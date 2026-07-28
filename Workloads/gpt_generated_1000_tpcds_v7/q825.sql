WITH filtered_items AS (
    SELECT i.i_item_sk,
           i.i_category,
           i.i_brand,
           i.i_item_desc,
           CONCAT(i.i_brand, ' ', i.i_product_name) AS brand_product,
           regexp_extract(i.i_item_desc, '^([A-Za-z]+)') AS first_word_desc
    FROM tpcds.item i
    WHERE i.i_brand LIKE 'A%'
      AND regexp_like(i.i_item_desc, '[0-9]{3}')
),
filtered_households AS (
    SELECT hd.hd_demo_sk,
           ib.ib_lower_bound,
           hd.hd_buy_potential
    FROM tpcds.household_demographics hd
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_buy_potential LIKE '%>10000%'
      AND ib.ib_lower_bound >= 150000
)
SELECT 
    f_i.i_category,
    f_i.first_word_desc,
    f_i.brand_product,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    MIN(ws.ws_net_paid_inc_tax) AS min_paid_inc_tax
FROM tpcds.web_sales ws
JOIN filtered_items f_i
  ON ws.ws_item_sk = f_i.i_item_sk
JOIN filtered_households f_h
  ON ws.ws_bill_hdemo_sk = f_h.hd_demo_sk
GROUP BY 
    f_i.i_category,
    f_i.first_word_desc,
    f_i.brand_product
ORDER BY total_profit DESC
LIMIT 20
