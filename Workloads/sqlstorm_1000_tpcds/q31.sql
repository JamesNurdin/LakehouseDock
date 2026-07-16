WITH cat_sales AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_net_paid AS net_paid,
           cs.cs_net_profit AS net_profit,
           d.d_date AS sale_date,
           cs.cs_quantity AS quantity,
           cs.cs_item_sk AS item_sk,
           cs.cs_order_number AS order_no,
           'Catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
),
store_sales_cte AS (
    SELECT ss.ss_customer_sk AS cust_sk,
           ss.ss_net_paid AS net_paid,
           ss.ss_net_profit AS net_profit,
           d.d_date AS sale_date,
           ss.ss_quantity AS quantity,
           ss.ss_item_sk AS item_sk,
           ss.ss_ticket_number AS order_no,
           'Store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
),
web_sales_cte AS (
    SELECT ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_net_paid AS net_paid,
           ws.ws_net_profit AS net_profit,
           d.d_date AS sale_date,
           ws.ws_quantity AS quantity,
           ws.ws_item_sk AS item_sk,
           ws.ws_order_number AS order_no,
           'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
),
all_sales AS (
    SELECT * FROM cat_sales
    UNION ALL
    SELECT * FROM store_sales_cte
    UNION ALL
    SELECT * FROM web_sales_cte
),
common_items AS (
    SELECT cs.cs_item_sk AS item_sk FROM catalog_sales cs
    INTERSECT
    SELECT ss.ss_item_sk FROM store_sales ss
),
sales_filtered AS (
    SELECT a.* FROM all_sales a JOIN common_items ci ON a.item_sk = ci.item_sk
),
cust_agg AS (
    SELECT c.c_customer_sk,
           c.c_first_name,
           c.c_last_name,
           COALESCE(SUM(s.net_paid), 0) AS total_net_paid,
           COALESCE(SUM(s.net_profit), 0) AS total_net_profit,
           COUNT(DISTINCT s.channel) AS channel_cnt,
           MAX(s.sale_date) AS last_sale_date
    FROM customer c
    LEFT JOIN sales_filtered s ON c.c_customer_sk = s.cust_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
ranked AS (
    SELECT ca.*,
           ROW_NUMBER() OVER (ORDER BY ca.total_net_profit DESC) AS profit_rank,
           RANK() OVER (ORDER BY ca.total_net_paid DESC) AS paid_rank
    FROM cust_agg ca
    WHERE ca.total_net_profit > 0
),
final AS (
    SELECT r.c_customer_sk,
           r.c_first_name,
           r.c_last_name,
           r.total_net_paid,
           r.total_net_profit,
           r.channel_cnt,
           r.last_sale_date,
           r.profit_rank,
           r.paid_rank,
           CASE
               WHEN r.profit_rank <= 10 THEN 'TOP10_PROFIT'
               WHEN r.paid_rank <= 10 THEN 'TOP10_PAID'
               ELSE 'OTHER'
           END AS segment,
           COALESCE(r.last_sale_date, DATE '1970-01-01') AS effective_last_sale,
           CONCAT('CUST_', CAST(r.c_customer_sk AS VARCHAR)) AS cust_key,
           (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = r.c_customer_sk AND sr.sr_return_quantity > 0) AS store_return_cnt,
           (SELECT MAX(sr.sr_returned_date_sk) FROM store_returns sr WHERE sr.sr_customer_sk = r.c_customer_sk) AS last_store_return_date_sk
    FROM ranked r
),
joined AS (
    SELECT f.*, cc.cc_call_center_id
    FROM final f
    FULL OUTER JOIN call_center cc
      ON (f.c_customer_sk % 10) = (cc.cc_call_center_sk % 10)
)
SELECT *
FROM joined
WHERE c_customer_sk IS NOT NULL
ORDER BY profit_rank
LIMIT 100
