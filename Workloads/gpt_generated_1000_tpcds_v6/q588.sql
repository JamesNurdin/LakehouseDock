WITH ws AS (
    SELECT
        ws_order_number,
        ws_bill_addr_sk,
        ws_ship_addr_sk,
        ws_web_site_sk,
        ws_sales_price,
        ws_net_paid_inc_ship_tax,
        ws_quantity,
        ws_item_sk,
        ws_sold_date_sk
    FROM tpcds.web_sales
    WHERE ws_sales_price > 20
      AND ws_net_paid_inc_ship_tax BETWEEN 1000 AND 8000
      AND ws_quantity >= 1
      AND ws_item_sk IS NOT NULL
      AND ws_web_site_sk IS NOT NULL
      AND ws_bill_addr_sk IS NOT NULL
),
ca AS (
    SELECT *
    FROM tpcds.customer_address
    WHERE ca_suite_number IN ('Suite 480 ', 'Suite B   ', 'Suite J   ')
      AND ca_country = 'United States'
),
ws_site AS (
    SELECT
        w.ws_order_number,
        w.ws_sales_price,
        w.ws_net_paid_inc_ship_tax,
        w.ws_quantity,
        w.ws_bill_addr_sk,
        w.ws_ship_addr_sk,
        w.ws_web_site_sk,
        w.ws_sold_date_sk,
        ca_bill.ca_city     AS bill_city,
        ca_ship.ca_city     AS ship_city,
        s.web_name,
        s.web_mkt_class,
        s.web_rec_start_date,
        s.web_tax_percentage
    FROM ws w
    JOIN ca ca_bill ON w.ws_bill_addr_sk = ca_bill.ca_address_sk
    JOIN ca ca_ship ON w.ws_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.web_site s ON w.ws_web_site_sk = s.web_site_sk
    WHERE s.web_rec_start_date >= DATE '1999-01-01'
      AND s.web_mkt_class LIKE '%Wide%'
      AND s.web_tax_percentage < 0.07
),
sr_agg AS (
    SELECT
        sr.sr_addr_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        COUNT(*)               AS cnt_returns,
        MAX(sr.sr_return_amt) AS max_return_amt
    FROM tpcds.store_returns sr
    WHERE sr.sr_return_amt > 0
      AND sr.sr_return_quantity > 0
      AND sr.sr_fee < 100
      AND sr.sr_return_tax < 50
      AND sr.sr_net_loss > 0
      AND EXISTS (
          SELECT 1
          FROM tpcds.customer_address ca2
          WHERE ca2.ca_address_sk = sr.sr_addr_sk
            AND ca2.ca_state = 'CA'
      )
    GROUP BY sr.sr_addr_sk
)
SELECT
    ws_site.ws_order_number,
    ws_site.ws_sales_price,
    ws_site.ws_net_paid_inc_ship_tax,
    ws_site.bill_city,
    ws_site.ship_city,
    ws_site.web_name,
    ws_site.web_mkt_class,
    ws_site.web_rec_start_date,
    COALESCE(sr_agg.total_return_amt, 0) AS total_return_amt,
    RANK() OVER (PARTITION BY ws_site.web_name ORDER BY ws_site.ws_net_paid_inc_ship_tax DESC) AS sales_rank_by_site,
    ROW_NUMBER() OVER (ORDER BY ws_site.ws_net_paid_inc_ship_tax DESC) AS global_rank,
    CASE
        WHEN sr_agg.cnt_returns > 5 THEN 'High Returns'
        WHEN sr_agg.cnt_returns BETWEEN 1 AND 5 THEN 'Medium Returns'
        ELSE 'Low Returns'
    END AS return_category
FROM ws_site
LEFT JOIN sr_agg
    ON ws_site.ws_ship_addr_sk = sr_agg.sr_addr_sk
ORDER BY ws_site.ws_net_paid_inc_ship_tax DESC
LIMIT 100
