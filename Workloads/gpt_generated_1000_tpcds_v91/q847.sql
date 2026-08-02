WITH item_excl AS (
    SELECT sr.sr_item_sk AS item_sk
    FROM store_returns sr
    EXCEPT
    SELECT cr.cr_item_sk
    FROM catalog_returns cr
)
SELECT
    i.i_item_id,
    i.i_product_name,
    cd.cd_gender,
    hd.hd_income_band_sk,
    p.p_promo_name,
    COUNT(DISTINCT ws.ws_order_number) AS num_orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amt,
    AVG(ws.ws_ext_discount_amt) AS avg_discount,
    MIN(ws.ws_sold_date_sk) AS first_sold_date_sk,
    MAX(ws.ws_sold_date_sk) AS last_sold_date_sk
FROM web_sales ws
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk AND p.p_item_sk = i.i_item_sk
JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN store_returns sr ON i.i_item_sk = sr.sr_item_sk
JOIN catalog_returns cr ON i.i_item_sk = cr.cr_item_sk
JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number AND ws.ws_item_sk = wr.wr_item_sk
JOIN item_excl ie ON i.i_item_sk = ie.item_sk
WHERE i.i_current_price > 100.00
  AND cd.cd_gender = 'M'
  AND p.p_start_date_sk = 2450347
  AND NOT EXISTS (
        SELECT 1 FROM web_returns wr2 WHERE wr2.wr_order_number = ws.ws_order_number
    )
GROUP BY i.i_item_id, i.i_product_name, cd.cd_gender, hd.hd_income_band_sk, p.p_promo_name
HAVING SUM(ws.ws_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
