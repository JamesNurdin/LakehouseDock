WITH joined_all AS (
    SELECT
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        cr.cr_returned_date_sk,
        sm.sm_code,
        w.w_state,
        w.w_warehouse_id,
        i.i_brand,
        i.i_category,
        c.c_customer_sk,
        hd.hd_income_band_sk,
        CASE WHEN cr.cr_net_loss > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE sm.sm_code IN ('AIR', 'SEA')
      AND w.w_state = 'CA'
      AND i.i_brand = 'BrandX'
      AND inv.inv_quantity_on_hand > 0
)
SELECT
    w_warehouse_id,
    sm_code,
    SUM(cr_net_loss) AS total_catalog_loss,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    SUM(CASE WHEN cr_net_loss > 1000 THEN 1 ELSE 0 END) AS high_loss_events
FROM joined_all
GROUP BY w_warehouse_id, sm_code
HAVING SUM(cr_net_loss) > 5000
ORDER BY total_catalog_loss DESC
LIMIT 100
