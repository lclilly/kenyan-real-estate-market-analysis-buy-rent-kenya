# kenyan-real-estate-market-analysis-buy-rent-kenya
This project analyzes Kenya’s property market using scraped data from BuyRent Kenya. The analysis serves two main audiences:  Investors &amp; real estate companies → Identify profitable regions &amp; property categories.  Home buyers → Discover affordable housing &amp; trends by location.

🛠 Tech Stack & Tools

Python → Data extraction, cleaning, exploratory analysis

Libraries:
>requests → API calls for scraping
>pandas / numpy → Data wrangling & preprocessing
>matplotlib → Exploratory visualizations

Power BI → Interactive dashboard creation & storytelling

GitHub → Project documentation & code versioning

📂 Process Workflow

Data Collection
>Used Python & API endpoint to scrape 300 out of 454 pages of property listings.
>Data saved into CSV format for further analysis.

Data Cleaning & Preparation (Python)
>Handled missing prices (marked as "Price not communicated")
>Converted price column to numeric (KES) and created price_m (millions)
>Removed duplicates & standardized location and property type fields
>Checked for outliers in prices and filtered them for certain analyses

Exploratory Data Analysis (EDA)
>Supply distribution by county & property category
>Price per square meter by county
>Bedroom count distribution
>Top 10 most expensive & least expensive properties
>Average prices by property type

Visualization in Power BI Dashboard includes:
>KPIs: Total properties, average price, median price
>Top 10 expensive & least expensive properties
>Count of properties by bedrooms
>Average price (KES millions) by property type
>Counties with most listings

📊 Key Insights

> Nairobi leads in supply — apartments/flats dominate.
> Commercial properties show the highest average asking prices (~KES 196M).
> Affordable properties exist — some land listings under KES 200K.
> Bedroom supply peaks in the 2–4 range, indicating mid-size family homes dominate.

