-- Goal: Identify the top 100 items by combined catalog and web net profit, applying price and demographic filters,
-- categorising items by price, showing return amounts, and excluding items that have an inactive promotion.

WITH cs_agg AS (
    SELECT
        cs_item_sk AS i_item_sk,
        SUM(cs.cs_net_paid_inc_tax) AS cat_sales,
        SUM(cs.cs_net_profit) AS cat_profit,
        MIN(cs.cs_ship_mode_sk) AS ship_mode_sk,
        MIN(cs.cs_bill_cdemo_sk) AS cd_demo_sk,
        MIN(cs.cs_bill_hdemo_sk) AS hd_demo_sk
    FROM catalog_sales cs
    GROUP BY cs_item_sk
),
ws_agg AS (
    SELECT
        ws_item_sk AS i_item_sk,
        SUM(ws.ws_net_paid_inc_tax) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        MIN(ws.ws_web_page_sk) AS web_page_sk,
        MIN(ws.ws_web_site_sk) AS web_site_sk
    FROM web_sales ws
    GROUP BY ws_item_sk
),
cr_agg AS (
    SELECT
        cr_item_sk AS i_item_sk,
        SUM(cr.cr_return_amt_inc_tax) AS cat_return_amount
    FROM catalog_returns cr
    GROUP BY cr_item_sk
),
sr_agg AS (
    SELECT
        sr_item_sk AS i_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS store_return_amount,
        MIN(sr.sr_store_sk) AS store_sk
    FROM store_returns sr
    GROUP BY sr_item_sk
),
wr_agg AS (
    SELECT
        wr_item_sk AS i_item_sk,
        SUM(wr.wr_return_amt_inc_tax) AS web_return_amount
    FROM web_returns wr
    GROUP BY wr_item_sk
)
SELECT
    i.i_item_sk,
    i.i_product_name,
    i.i_current_price,
    CASE WHEN i.i_current_price > 500 THEN 'Expensive' ELSE 'Regular' END AS price_category,
    (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price,
    cd.cd_gender,
    hd.hd_buy_potential,
    p.p_promo_name,
    sm.sm_carrier,
    wp.wp_type,
    wsite.web_name,
    s.s_store_name,
    cs_agg.cat_sales,
    ws_agg.web_sales,
    cs_agg.cat_profit,
    ws_agg.web_profit,
    cr_agg.cat_return_amount,
    sr_agg.store_return_amount,
    wr_agg.web_return_amount,
    (cs_agg.cat_profit + ws_agg.web_profit) AS total_profit,
    RANK() OVER (ORDER BY (cs_agg.cat_profit + ws_agg.web_profit) DESC) AS profit_rank
FROM item i
LEFT JOIN cs_agg ON cs_agg.i_item_sk = i.i_item_sk
LEFT JOIN ws_agg ON ws_agg.i_item_sk = i.i_item_sk
LEFT JOIN cr_agg ON cr_agg.i_item_sk = i.i_item_sk
LEFT JOIN sr_agg ON sr_agg.i_item_sk = i.i_item_sk
LEFT JOIN wr_agg ON wr_agg.i_item_sk = i.i_item_sk
LEFT JOIN promotion p ON p.p_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm ON sm.sm_ship_mode_sk = cs_agg.ship_mode_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = cs_agg.cd_demo_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cs_agg.hd_demo_sk
LEFT JOIN store s ON s.s_store_sk = sr_agg.store_sk
LEFT JOIN web_page wp ON wp.wp_web_page_sk = ws_agg.web_page_sk
LEFT JOIN web_site wsite ON wsite.web_site_sk = ws_agg.web_site_sk
WHERE i.i_current_price > 100
  AND cd.cd_gender = 'F'
  AND hd.hd_buy_potential = '5001-10000'
  AND cs_agg.cat_sales > 1000
  AND i.i_item_sk NOT IN (SELECT p2.p_item_sk FROM promotion p2 WHERE p2.p_discount_active = 'N')
LIMIT 100
