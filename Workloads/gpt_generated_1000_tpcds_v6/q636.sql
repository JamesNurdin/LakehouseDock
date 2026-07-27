WITH joined_data AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        i.i_class,
        cr.cr_return_amount,
        ws.ws_net_profit,
        hd.hd_income_band_sk,
        w.w_state
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_class_id IN (2, 3, 4)
      AND i.i_brand = 'brandbrand #4'
      AND hd.hd_income_band_sk >= 10
      AND w.w_state = 'CA'
      AND cr.cr_return_amount > 100
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    jd.i_item_id,
    jd.i_brand,
    jd.i_class,
    SUM(jd.cr_return_amount) AS total_return_amount,
    SUM(jd.ws_net_profit) AS total_net_profit,
    (SELECT AVG(i2.i_current_price) FROM item i2 WHERE i2.i_brand = jd.i_brand) AS avg_price_by_brand,
    RANK() OVER (PARTITION BY jd.i_brand ORDER BY SUM(jd.cr_return_amount) DESC) AS brand_return_rank
FROM joined_data jd
GROUP BY jd.i_item_id, jd.i_brand, jd.i_class
ORDER BY brand_return_rank, total_return_amount DESC
LIMIT 100
