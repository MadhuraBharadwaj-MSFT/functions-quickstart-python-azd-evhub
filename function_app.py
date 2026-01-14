import azure.functions as func
import logging
import json
from datetime import datetime, timezone
import random
import uuid
from typing import List

app = func.FunctionApp()

# News article data model
class NewsArticle:
    def __init__(self, article_id: str, title: str, content: str, author: str, 
                 source: str, category: str, published_date: datetime, 
                 view_count: int, sentiment_score: float, status: str, tags: List[str]):
        self.article_id = article_id
        self.title = title
        self.content = content
        self.author = author
        self.source = source
        self.category = category
        self.published_date = published_date
        self.view_count = view_count
        self.sentiment_score = sentiment_score
        self.status = status
        self.tags = tags
    
    def to_dict(self):
        return {
            "ArticleId": self.article_id,
            "Title": self.title,
            "Content": self.content,
            "Author": self.author,
            "Source": self.source,
            "Category": self.category,
            "PublishedDate": self.published_date.isoformat(),
            "ViewCount": self.view_count,
            "SentimentScore": self.sentiment_score,
            "Status": self.status,
            "Tags": self.tags
        }

# Timer trigger - generates news every 10 seconds
@app.timer_trigger(schedule="0,10,20,30,40,50 * * * * *", arg_name="timer", run_on_startup=True)
@app.event_hub_output(arg_name="event", event_hub_name="news", connection="EventHubConnection")
def NewsGenerator(timer: func.TimerRequest, event: func.Out[str]) -> None:
    """Generate realistic news articles and send to Event Hub"""
    logging.info(f'🗞️ HIGH-THROUGHPUT News Generator started at: {datetime.now(timezone.utc)}')
    
    # Generate 3-8 articles
    num_articles = random.randint(3, 8)
    articles = []
    
    # Sample data
    titles_templates = [
        "Breaking: Major Discovery in {topic}",
        "New {topic} Study Reveals Surprising Benefits",
        "{topic} Industry Faces Major Transformation",
        "Global Markets Show Strong Recovery Amid {topic}",
        "International Trade Agreements Reshape {topic}",
        "Sports Stars Unite for {topic}",
        "Cultural Festival Celebrates {topic}",
        "Technology Breakthrough in {topic}"
    ]
    
    topics = ["Renewable Energy Technology", "Artificial Intelligence", "Climate Change",
              "Space Exploration", "Healthcare Innovation", "Economic Policy",
              "Sports Excellence", "Cultural Diversity", "Quantum Computing",
              "Sustainable Agriculture"]
    
    authors = ["Sarah Johnson", "Michael Chen", "Emily Rodriguez", "David Kim",
               "Lisa Zhang", "Alex Thompson", "Maria Garcia", "James Wilson"]
    
    sources = ["Tech Today", "Health Herald", "Finance Focus", "Sports Spotlight",
               "Culture Corner", "Science Daily", "Global News", "Innovation Weekly"]
    
    categories = ["Technology", "Health", "Business", "Sports", "Culture", "Science"]
    
    for _ in range(num_articles):
        topic = random.choice(topics)
        article_id = f"NEWS-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"
        
        article = NewsArticle(
            article_id=article_id,
            title=random.choice(titles_templates).format(topic=topic),
            content=f"Comprehensive coverage of the latest developments in {topic}. " * random.randint(10, 20),
            author=random.choice(authors),
            source=random.choice(sources),
            category=random.choice(categories),
            published_date=datetime.now(timezone.utc),
            view_count=random.randint(100, 10000),
            sentiment_score=round(random.uniform(-1.0, 1.0), 2),
            status=random.choice(["Published", "Featured"]),
            tags=[random.choice(topics) for _ in range(random.randint(3, 5))]
        )
        articles.append(article)
    
    # Send articles to Event Hub
    events_json = json.dumps([article.to_dict() for article in articles])
    event.set(events_json)
    
    logging.info(f'✅ HIGH-THROUGHPUT: Successfully generated {num_articles} news articles in ~10 seconds')


# Event Hub trigger - processes news articles
@app.event_hub_message_trigger(arg_name="events", event_hub_name="news",
                                connection="EventHubConnection")
def EventHubsTrigger(events: List[func.EventHubEvent]):
    """Process news articles from Event Hub with sentiment analysis and engagement tracking"""
    
    # Handle both single event and list of events
    if not isinstance(events, list):
        events = [events]
    
    batch_articles = []
    failed_count = 0
    
    for event in events:
        try:
            # Parse the event data
            event_data = json.loads(event.get_body().decode('utf-8'))
            
            # Handle both single article and array of articles
            articles = event_data if isinstance(event_data, list) else [event_data]
            
            for article_data in articles:
                # Process each article
                article_id = article_data.get('ArticleId')
                title = article_data.get('Title')
                author = article_data.get('Author')
                view_count = article_data.get('ViewCount', 0)
                sentiment = article_data.get('SentimentScore', 0.0)
                status = article_data.get('Status', 'Published')
                tags = article_data.get('Tags', [])
                
                # Track for batch summary
                batch_articles.append(article_data)
                
                # High-engagement detection
                if view_count >= 5000:
                    logging.info(f'⭐ High-engagement article {article_id} (Views: {view_count}, Sentiment: {sentiment:.2f}) featured!')
                
                # Viral article detection
                if view_count >= 5000:
                    logging.info(f'🔥 Viral article: {article_id} - {view_count:,} views')
                
                # Status logging
                if status == "Featured":
                    logging.info(f'🌟 Featured article: {article_id}')
                else:
                    logging.info(f'📰 Article {article_id} remains published')
                
                # Strong sentiment detection
                if abs(sentiment) >= 0.7:
                    emoji = "😊" if sentiment > 0 else "😢"
                    logging.info(f'{emoji} Strong {"positive" if sentiment > 0 else "negative"} sentiment: {article_id} ({sentiment:.2f})')
                
                # Well-tagged articles
                if len(tags) >= 5:
                    logging.info(f'🏷️ Well-tagged article: {article_id} - {len(tags)} tags')
                
                # Success log
                logging.info(f'✅ Successfully processed article {article_id} - \'{title}\' by {author}')
                
        except Exception as e:
            failed_count += 1
            logging.error(f'Error processing event: {str(e)}')
    
    # Log batch processing summary
    total = len(batch_articles)
    logging.info(f'📰 Processed {total} news articles, {failed_count} failed in batch of {len(events)}')
    
    if batch_articles:
        # Calculate batch statistics
        total_views = sum(a.get('ViewCount', 0) for a in batch_articles)
        avg_views = total_views // total if total > 0 else 0
        avg_sentiment = sum(a.get('SentimentScore', 0.0) for a in batch_articles) / total if total > 0 else 0.0
        
        # Count by status
        status_counts = {}
        for article in batch_articles:
            status = article.get('Status', 'Unknown')
            status_counts[status] = status_counts.get(status, 0) + 1
        status_str = ', '.join([f'{k}: {v}' for k, v in status_counts.items()])
        
        logging.info(f'📊 NEWS BATCH SUMMARY: {total} articles | Total Views: {total_views:,} | '
                    f'Avg Views: {avg_views:,} | Avg Sentiment: {avg_sentiment:.2f} | Status: [{status_str}]')
        
        # Category and source analysis
        categories = {}
        sources = {}
        for article in batch_articles:
            cat = article.get('Category', 'Unknown')
            src = article.get('Source', 'Unknown')
            categories[cat] = categories.get(cat, 0) + 1
            sources[src] = sources.get(src, 0) + 1
        
        top_cats = sorted(categories.items(), key=lambda x: x[1], reverse=True)[:3]
        top_srcs = sorted(sources.items(), key=lambda x: x[1], reverse=True)[:3]
        
        cats_str = ', '.join([f'{k}: {v}' for k, v in top_cats])
        srcs_str = ', '.join([f'{k}: {v}' for k, v in top_srcs])
        
        logging.info(f'📂 Top Categories: [{cats_str}] | Top Sources: [{srcs_str}]')
        
        # Viral and well-tagged article counts
        viral_count = sum(1 for a in batch_articles if a.get('ViewCount', 0) >= 5000)
        well_tagged = sum(1 for a in batch_articles if len(a.get('Tags', [])) >= 5)
        strong_sentiment = sum(1 for a in batch_articles if abs(a.get('SentimentScore', 0.0)) >= 0.7)
        
        if viral_count > 0:
            logging.info(f'🔥 Viral articles in batch: {viral_count}')
        if strong_sentiment > 0:
            logging.info(f'😊😢 Strong sentiment articles in batch: {strong_sentiment}')
        if well_tagged > 0:
            logging.info(f'🏷️ Well-tagged articles in batch: {well_tagged}')
