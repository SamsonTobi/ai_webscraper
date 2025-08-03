# Event Scraper Examples

This directory contains practical examples demonstrating how to use the AI WebScraper package to extract event information from websites using Gemini AI.

## Examples

### 1. Simple Event Scraper (`simple_event_scraper.dart`)

A standalone command-line application that scrapes event websites and extracts:

- Event title
- Description
- Ticket/registration links
- Date and time
- Venue/location
- Price information
- Organizer details

**Usage:**

```powershell
# Set your Gemini API key
$env:GEMINI_API_KEY="your-gemini-api-key-here"

# Run the scraper
dart run example/simple_event_scraper.dart
```

### 2. Event Scraper Server (`event_scraper_server.dart`)

A HTTP server using Shelf that provides REST API endpoints for event scraping. Perfect for integrating event scraping into web applications.

**Features:**

- REST API with JSON responses
- CORS support for web applications
- Health check endpoint
- Detailed logging and error handling

**Usage:**

```powershell
# Set your Gemini API key
$env:GEMINI_API_KEY="your-gemini-api-key-here"

# Start the server
dart run example/event_scraper_server.dart

# Test with curl
curl -X POST http://localhost:8080/scrape-event \
  -H "Content-Type: application/json" \
  -d '{"url": "https://your-event-website.com"}'
```

## Getting Your Gemini API Key

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Create a new API key
4. Copy the API key for use in the examples

## Supported Event Websites

The scraper works best with structured event websites such as:

- Eventbrite events
- Facebook Events
- Meetup events
- Ticketmaster events
- Custom event websites with clear structure

## Example Event Data Structure

The scraper extracts the following information:

```json
{
  "title": "Tech Conference 2024",
  "description": "Annual technology conference featuring the latest in AI and web development",
  "ticketLink": "https://example.com/tickets",
  "date": "March 15, 2024",
  "time": "9:00 AM - 5:00 PM",
  "venue": "Convention Center, 123 Main St, City, State",
  "price": "$99 - $299",
  "organizer": "Tech Events Inc."
}
```

## Customization

### Modifying the Schema

You can customize the data extraction by modifying the `eventSchema` in the examples:

```dart
final customSchema = {
  'eventName': 'string - The name of the event',
  'speakers': 'array - List of speakers or performers',
  'categories': 'array - Event categories or tags',
  'capacity': 'number - Maximum number of attendees',
  // Add more fields as needed
};
```

### Custom Prompts

Enhance extraction accuracy with specific prompts:

```dart
final result = await scraper.extractFromUrl(
  url: url,
  schema: eventSchema,
  prompt: '''
  Focus on extracting information for a music concert:
  - Look for artist/band names
  - Find venue capacity and seating information
  - Extract opening acts or supporting artists
  - Get VIP package details if available
  ''',
);
```

## Error Handling

Both examples include comprehensive error handling:

- Network timeouts
- Invalid URLs
- AI extraction failures
- Missing API keys
- Malformed responses

## Performance Tips

1. **Use JavaScript scraping** for dynamic content: `useJavaScript: true`
2. **Adjust timeouts** for slow websites: `timeout: Duration(seconds: 60)`
3. **Batch process** multiple URLs using the built-in batch processor
4. **Cache results** to avoid re-scraping the same content

## Troubleshooting

### Common Issues

1. **"GEMINI_API_KEY not set"**

   - Ensure you've set the environment variable correctly
   - Check that the API key is valid and has proper permissions

2. **Timeout errors**

   - Increase the timeout duration for slow websites
   - Try with JavaScript scraping enabled

3. **Empty results**

   - Verify the URL is publicly accessible
   - Check that the website contains the expected event information
   - Try adjusting the extraction prompt

4. **Rate limiting**
   - Add delays between requests when processing multiple URLs
   - Consider using different API keys for high-volume usage

## Advanced Usage

### Batch Processing Multiple Events

```dart
final urls = [
  'https://event1.com',
  'https://event2.com',
  'https://event3.com',
];

final results = await scraper.extractFromUrls(
  urls: urls,
  schema: eventSchema,
  maxConcurrency: 3,
);
```

### Custom AI Options

```dart
final scraper = AIWebScraper(
  aiModel: AIModel.gemini15Pro,
  apiKey: apiKey,
  aiOptions: {
    'temperature': 0.1,
    'maxTokens': 2000,
  },
);
```

## Contributing

Feel free to extend these examples or create new ones for specific use cases like:

- Conference scraping
- Workshop extraction
- Festival information gathering
- Local event discovery
