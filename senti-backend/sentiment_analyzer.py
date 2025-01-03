from textblob import TextBlob

def analyze_sentiment(text):
    """
    Analyze sentiment of input text
    Returns: 'positive', 'negative', or 'neutral'
    """
    sentiment = TextBlob(text).sentiment.polarity
    
    if sentiment > 0.2:
        return 'positive'
    elif sentiment < -0.2:
        return 'negative'
    else:
        return 'neutral'
