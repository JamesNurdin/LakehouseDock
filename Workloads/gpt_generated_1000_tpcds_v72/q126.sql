WITH catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS profit,
        SUM(cs.cs_quantity) AS qty
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND i.i_color LIKE 'B%'
    GROUP BY cs.cs_bill_customer_sk, cs.cs_item_sk
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS profit,
        SUM(ws.ws_quantity) AS qty
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE regexp_like(i.i_item_desc, '[A-Z]{2}[0-9]{3}')
      AND i.i_color LIKE 'B%'
    GROUP BY ws.ws_bill_customer_sk, ws.ws_item_sk
),
combined AS (
    SELECT cust_sk, item_sk, profit, qty, 'catalog' AS channel FROM catalog_agg
    UNION ALL
    SELECT cust_sk, item_sk, profit, qty, 'web' AS channel FROM web_agg
),
ranked AS (
    SELECT
        comb.cust_sk,
        comb.item_sk,
        comb.profit,
        comb.qty,
        comb.channel,
        ROW_NUMBER() OVER (PARTITION BY comb.cust_sk ORDER BY comb.profit DESC) AS rn,
        (
            SELECT SUM(c2.profit)
            FROM combined c2
            WHERE c2.cust_sk = comb.cust_sk
        ) AS total_cust_profit
    FROM combined comb
)
SELECT
    c.c_customer_id,
    concat(c.c_first_name, ' ', c.c_last_name) AS customer_name,
    i.i_item_id,
    i.i_product_name,
    substring(i.i_item_desc FROM 1 FOR 30) AS short_desc,
    regexp_extract(i.i_item_desc, '([A-Z]{2}[0-9]{3})', 1) AS extracted_code,
    r.channel,
    r.profit,
    r.qty,
    r.total_cust_profit
FROM ranked r
JOIN customer c ON r.cust_sk = c.c_customer_sk
JOIN item i ON r.item_sk = i.i_item_sk
WHERE r.rn <= 5
  AND regexp_like(c.c_email_address, '^.+@example\\.com$')
  AND NOT EXISTS (
        SELECT 1
        FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
          AND sr.sr_item_sk = i.i_item_sk
    )
ORDER BY r.total_cust_profit DESC, r.profit DESC
LIMIT 100
