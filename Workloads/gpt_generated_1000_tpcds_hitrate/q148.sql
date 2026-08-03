WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        i.i_brand,
        i.i_category,
        p.p_promo_name,
        p.p_cost,
        p.p_start_date_sk,
        ws.ws_sold_date_sk,
        td.t_hour,
        wr.wr_return_quantity,
        wr.wr_return_amt_inc_tax,
        web_site.web_name,
        web_site.web_country,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS rn_item_sales,
        RANK() OVER (ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site
        ON ws.ws_web_site_sk = web_site.web_site_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE ws.ws_quantity > 5
      AND ws.ws_sales_price BETWEEN 100 AND 500
      AND p.p_cost > 500
      AND p.p_start_date_sk BETWEEN 2450000 AND 2451000
      AND i.i_brand = 'Brand#12'
      AND web_site.web_country = 'United States'
      AND td.t_hour BETWEEN 9 AND 17
      AND (wr.wr_return_amt_inc_tax IS NULL OR wr.wr_return_amt_inc_tax > 100)
)
SELECT
    sr.ws_order_number,
    sr.ws_item_sk,
    sr.i_brand,
    sr.i_category,
    sr.p_promo_name,
    sr.web_name,
    sr.t_hour,
    sr.ws_ext_sales_price,
    sr.ws_net_profit,
    sr.rn_item_sales,
    sr.profit_rank,
    cat_dim.i_category AS cross_category,
    tier.tier
FROM sales_returns sr
CROSS JOIN (
    SELECT DISTINCT i_category
    FROM item
    WHERE i_category IS NOT NULL
    LIMIT 5
) AS cat_dim
CROSS JOIN (
    SELECT 1 AS tier UNION ALL SELECT 2 UNION ALL SELECT 3
) AS tier
ORDER BY sr.profit_rank ASC, sr.ws_net_profit DESC
LIMIT 100
