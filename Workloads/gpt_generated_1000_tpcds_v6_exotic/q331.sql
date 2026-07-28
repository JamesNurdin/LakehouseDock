WITH base_agg AS (
    SELECT
        s.s_store_sk,
        i.i_brand,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt,
        SUM(CASE WHEN ss.ss_quantity > 10 THEN ss.ss_quantity ELSE 0 END) AS high_qty_sum,
        SUM(CASE WHEN ss.ss_quantity <= 10 THEN ss.ss_quantity ELSE 0 END) AS low_qty_sum,
        SUM(CASE WHEN ss.ss_net_paid > 1000 THEN 1 ELSE 0 END) AS high_value_sales,
        CASE WHEN SUM(ss.ss_net_paid) > 5000 THEN 'High' ELSE 'Low' END AS store_sales_category
    FROM store_sales ss
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = td.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
      AND td.t_hour BETWEEN 9 AND 17
      AND inv.inv_quantity_on_hand > 0
    GROUP BY s.s_store_sk, i.i_brand
    HAVING SUM(ss.ss_net_paid) > 1000
)
SELECT
    store_sales_category,
    AVG(total_net_paid) AS avg_total_net_paid,
    SUM(sales_cnt) AS total_sales_cnt
FROM base_agg
GROUP BY store_sales_category
HAVING AVG(total_net_paid) > 2000
ORDER BY avg_total_net_paid DESC
LIMIT 100
