WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
),
promo_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        p.p_promo_name,
        regexp_extract(p.p_promo_name, '(.*)Discount(.*)', 1) AS before_discount,
        concat(p.p_promo_name, '_', CAST(ws.ws_order_number AS varchar)) AS promo_key
    FROM sampled_ws ws
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_promo_name, 'Discount')
),
agg_sales AS (
    SELECT
        ws_order_number,
        sum(ws_ext_sales_price) AS total_sales,
        max(promo_key) AS any_promo_key
    FROM promo_sales
    GROUP BY ws_order_number
),
returns_filtered AS (
    SELECT
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_reason_sk
    FROM web_returns wr
    WHERE wr.wr_return_amt > 0
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr
          WHERE sr.sr_ticket_number = wr.wr_order_number
      )
),
intersect_keys AS (
    SELECT ws_order_number FROM agg_sales
    INTERSECT
    SELECT wr_order_number FROM returns_filtered
)
SELECT
    i.ws_order_number,
    a.total_sales,
    a.any_promo_key
FROM intersect_keys i
JOIN agg_sales a ON i.ws_order_number = a.ws_order_number
ORDER BY a.total_sales DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
