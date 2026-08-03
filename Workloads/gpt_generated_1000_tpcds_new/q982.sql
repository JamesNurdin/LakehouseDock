WITH store_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND c.c_birth_country LIKE 'U%'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_item_desc
),
web_agg AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_item_desc AS item_desc,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
      AND c.c_birth_country LIKE 'U%'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_item_sk = i.i_item_sk
            AND p.p_discount_active = 'Y'
      )
    GROUP BY i.i_item_id, i.i_item_desc
)
SELECT
    ROW_NUMBER() OVER (ORDER BY u.total_sales DESC) AS rn,
    u.item_id,
    u.item_desc,
    u.total_sales,
    u.total_profit,
    CASE WHEN u.total_profit > 0 THEN 'Positive' ELSE 'Negative' END AS profit_sign,
    u.total_sales / (SELECT avg(ss_ext_sales_price) FROM store_sales) AS sales_vs_avg
FROM (
    SELECT * FROM store_agg
    UNION
    SELECT * FROM web_agg
) u
ORDER BY u.total_sales DESC
LIMIT 100
