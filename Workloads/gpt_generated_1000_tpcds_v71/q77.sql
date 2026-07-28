/* Goal: Rank customers by total net profit across store, catalog, and web channels for the year 2001 in the 'Sports' category, showing how each sale compares to the channel average profit. */
WITH sales_agg AS (
    /* Store sales */
    SELECT
        ss.ss_customer_sk AS c_customer_sk,
        d.d_date,
        d.d_year,
        i.i_category,
        ss.ss_net_profit AS net_profit,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
      AND ss.ss_quantity > 1

    UNION ALL

    /* Catalog sales */
    SELECT
        cs.cs_bill_customer_sk AS c_customer_sk,
        d2.d_date,
        d2.d_year,
        i2.i_category,
        cs.cs_net_profit AS net_profit,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
    JOIN time_dim t2 ON cs.cs_sold_time_sk = t2.t_time_sk
    JOIN customer c2 ON cs.cs_bill_customer_sk = c2.c_customer_sk
    JOIN item i2 ON cs.cs_item_sk = i2.i_item_sk
    WHERE d2.d_year = 2001
      AND i2.i_category = 'Sports'
      AND cs.cs_quantity > 1

    UNION ALL

    /* Web sales with optional return information (LEFT OUTER JOIN) */
    SELECT
        ws.ws_bill_customer_sk AS c_customer_sk,
        d3.d_date,
        d3.d_year,
        i3.i_category,
        ws.ws_net_profit AS net_profit,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d3 ON ws.ws_sold_date_sk = d3.d_date_sk
    JOIN time_dim t3 ON ws.ws_sold_time_sk = t3.t_time_sk
    JOIN customer c3 ON ws.ws_bill_customer_sk = c3.c_customer_sk
    JOIN item i3 ON ws.ws_item_sk = i3.i_item_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
                           AND ws.ws_item_sk = wr.wr_item_sk
    WHERE d3.d_year = 2001
      AND i3.i_category = 'Sports'
      AND ws.ws_quantity > 1
      AND ws.ws_ext_list_price > 5000
)
SELECT
    c.c_customer_id,
    s.d_date,
    s.channel,
    s.net_profit,
    AVG(s.net_profit) OVER (PARTITION BY s.channel) AS avg_channel_profit,
    ROW_NUMBER() OVER (PARTITION BY s.d_year ORDER BY s.net_profit DESC) AS profit_rank,
    CASE
        WHEN s.net_profit > (
                SELECT AVG(net_profit)
                FROM sales_agg sa_sub
                WHERE sa_sub.channel = s.channel
            ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_vs_avg
FROM sales_agg s
JOIN customer c ON s.c_customer_sk = c.c_customer_sk
WHERE s.net_profit IS NOT NULL
ORDER BY s.d_year, profit_rank
LIMIT 100
