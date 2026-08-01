WITH store_sales_agg AS (
    SELECT
        ss_store_sk,
        ss_item_sk,
        SUM(ss_net_paid) AS ss_total_net_paid,
        SUM(ss_quantity) AS ss_total_quantity
    FROM store_sales
    GROUP BY ss_store_sk, ss_item_sk
)
SELECT
    s.s_store_name,
    i.i_item_sk,
    MAX(i.i_product_name) AS product_name,
    d_cs_sold.d_year,
    SUM(ssa.ss_total_net_paid) AS sum_store_sales_net_paid,
    SUM(cs.cs_ext_sales_price) AS sum_catalog_sales_ext_price,
    SUM(ws.ws_net_paid) AS sum_web_sales_net_paid,
    SUM(sr.sr_return_amt) AS sum_store_returns_amount,
    SUM(wr.wr_return_amt) AS sum_web_returns_amount,
    (
        SELECT MAX(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = i.i_item_sk
    ) AS max_catalog_net_paid_item,
    CASE
        WHEN SUM(ssa.ss_total_quantity) = 0 THEN NULL
        ELSE SUM(ssa.ss_total_net_paid) / SUM(ssa.ss_total_quantity)
    END AS avg_store_sales_price_per_qty
FROM store_sales_agg ssa
JOIN store s
    ON ssa.ss_store_sk = s.s_store_sk
JOIN item i
    ON ssa.ss_item_sk = i.i_item_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d_cs_sold
    ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN date_dim d_promo_start
    ON p.p_start_date_sk = d_promo_start.d_date_sk
JOIN date_dim d_promo_end
    ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sold
    ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
    ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN promotion p_ws
    ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN store_returns sr
    ON sr.sr_store_sk = s.s_store_sk
   AND sr.sr_item_sk = i.i_item_sk
JOIN date_dim d_sr_return
    ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
JOIN customer_demographics cd_sr
    ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
JOIN household_demographics hd_sr
    ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
JOIN income_band ib_sr
    ON hd_sr.hd_income_band_sk = ib_sr.ib_income_band_sk
JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
JOIN date_dim d_wr_return
    ON wr.wr_returned_date_sk = d_wr_return.d_date_sk
JOIN customer_demographics cd_wr_ref
    ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
JOIN household_demographics hd_wr_ref
    ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
JOIN income_band ib_wr_ref
    ON hd_wr_ref.hd_income_band_sk = ib_wr_ref.ib_income_band_sk
JOIN date_dim d_store_closed
    ON s.s_closed_date_sk = d_store_closed.d_date_sk
GROUP BY ROLLUP (s.s_store_name, i.i_item_sk, d_cs_sold.d_year)
ORDER BY s.s_store_name, i.i_item_sk, d_cs_sold.d_year
LIMIT 100
