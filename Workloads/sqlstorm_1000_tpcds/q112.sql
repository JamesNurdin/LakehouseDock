WITH sales_union AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_customer_sk AS customer_sk,
        'store' AS channel,
        ss.ss_ticket_number AS transaction_id,
        (ss.ss_net_profit - COALESCE(sr.sr_net_loss, 0)) AS profit_adj,
        ss.ss_item_sk AS item_sk
    FROM store_sales ss
    LEFT JOIN store_returns sr
      ON ss.ss_ticket_number = sr.sr_ticket_number
     AND ss.ss_sold_date_sk = sr.sr_returned_date_sk
    UNION ALL
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        'catalog' AS channel,
        cs.cs_order_number AS transaction_id,
        (cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0)) AS profit_adj,
        cs.cs_item_sk AS item_sk
    FROM catalog_sales cs
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
     AND cs.cs_sold_date_sk = cr.cr_returned_date_sk
    UNION ALL
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        'web' AS channel,
        ws.ws_order_number AS transaction_id,
        (ws.ws_net_profit - COALESCE(wr.wr_net_loss, 0)) AS profit_adj,
        ws.ws_item_sk AS item_sk
    FROM web_sales ws
    LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
),
sales_daily AS (
    SELECT
        su.customer_sk,
        su.date_sk,
        d.d_date AS sold_date,
        su.channel,
        SUM(su.profit_adj) AS total_profit_adj,
        COUNT(DISTINCT su.item_sk) AS distinct_items
    FROM sales_union su
    LEFT JOIN date_dim d ON su.date_sk = d.d_date_sk
    GROUP BY su.customer_sk, su.date_sk, d.d_date, su.channel
),
ranked_sales AS (
    SELECT
        sd.*,
        ROW_NUMBER() OVER (PARTITION BY sd.customer_sk ORDER BY sd.total_profit_adj DESC) AS profit_rank,
        SUM(sd.total_profit_adj) OVER (PARTITION BY sd.customer_sk ORDER BY sd.sold_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_profit
    FROM sales_daily sd
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        concat(COALESCE(c.c_first_name, ''), ' ', COALESCE(c.c_last_name, '')) AS full_name,
        COALESCE(ca.ca_city, 'UNKNOWN') AS city_coalesce
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
top_sales AS (
    SELECT
        ci.full_name,
        ci.city_coalesce,
        rs.sold_date,
        rs.channel,
        rs.total_profit_adj,
        rs.distinct_items,
        rs.profit_rank,
        rs.cum_profit,
        CASE
            WHEN rs.total_profit_adj > 0 THEN 'POSITIVE'
            WHEN rs.total_profit_adj < 0 THEN 'NEGATIVE'
            ELSE 'ZERO'
        END AS profit_sign,
        (SELECT COUNT(*) FROM sales_union su2
           WHERE su2.customer_sk = rs.customer_sk
             AND su2.date_sk <= rs.date_sk) AS total_transactions_to_date,
        (SELECT MAX(su3.profit_adj) FROM sales_union su3
           WHERE su3.customer_sk = rs.customer_sk
             AND su3.date_sk <= rs.date_sk) AS max_profit_to_date
    FROM ranked_sales rs
    JOIN customer_info ci ON rs.customer_sk = ci.c_customer_sk
    WHERE rs.profit_rank <= 5
)
SELECT
    full_name,
    city_coalesce,
    sold_date,
    channel,
    total_profit_adj,
    distinct_items,
    profit_rank,
    cum_profit,
    profit_sign,
    total_transactions_to_date,
    max_profit_to_date
FROM top_sales
UNION ALL
SELECT
    ci.full_name,
    ci.city_coalesce,
    CAST(NULL AS date) AS sold_date,
    'summary' AS channel,
    SUM(rs.total_profit_adj) AS total_profit_adj,
    SUM(rs.distinct_items) AS distinct_items,
    CAST(NULL AS integer) AS profit_rank,
    MAX(rs.cum_profit) AS cum_profit,
    CASE
        WHEN SUM(rs.total_profit_adj) > 0 THEN 'POSITIVE'
        WHEN SUM(rs.total_profit_adj) < 0 THEN 'NEGATIVE'
        ELSE 'ZERO'
    END AS profit_sign,
    CAST(NULL AS integer) AS total_transactions_to_date,
    CAST(NULL AS decimal(15,2)) AS max_profit_to_date
FROM ranked_sales rs
JOIN customer_info ci ON rs.customer_sk = ci.c_customer_sk
GROUP BY ci.full_name, ci.city_coalesce
ORDER BY total_profit_adj DESC
LIMIT 200
