WITH
store_sales_agg AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_hdemo_sk AS hd_demo_sk,
        ss.ss_addr_sk AS address_sk,
        SUM(ss.ss_net_paid) AS total_store_sales_net_paid,
        SUM(ss.ss_quantity) AS total_store_sales_qty,
        COUNT(*) AS store_sales_txn
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk, ss.ss_promo_sk, ss.ss_hdemo_sk, ss.ss_addr_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        SUM(cs.cs_net_paid) AS total_catalog_sales_net_paid,
        SUM(cs.cs_quantity) AS total_catalog_sales_qty,
        COUNT(*) AS catalog_sales_txn
    FROM catalog_sales cs
    GROUP BY cs.cs_sold_date_sk, cs.cs_promo_sk, cs.cs_call_center_sk, cs.cs_warehouse_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS returned_date_sk,
        cr.cr_reason_sk AS reason_sk,
        SUM(cr.cr_return_amount) AS total_catalog_return_amount,
        SUM(cr.cr_return_quantity) AS total_catalog_return_qty,
        COUNT(*) AS catalog_return_txn
    FROM catalog_returns cr
    GROUP BY cr.cr_returned_date_sk, cr.cr_reason_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS returned_date_sk,
        sr.sr_store_sk AS store_sk,
        sr.sr_reason_sk AS reason_sk,
        SUM(sr.sr_return_amt) AS total_store_return_amt,
        SUM(sr.sr_return_quantity) AS total_store_return_qty,
        COUNT(*) AS store_return_txn
    FROM store_returns sr
    GROUP BY sr.sr_returned_date_sk, sr.sr_store_sk, sr.sr_reason_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_returned_date_sk AS returned_date_sk,
        wr.wr_web_page_sk AS web_page_sk,
        wr.wr_reason_sk AS reason_sk,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        SUM(wr.wr_return_quantity) AS total_web_return_qty,
        COUNT(*) AS web_return_txn
    FROM web_returns wr
    GROUP BY wr.wr_returned_date_sk, wr.wr_web_page_sk, wr.wr_reason_sk
),
inventory_agg AS (
    SELECT
        inv.inv_date_sk AS inv_date_sk,
        inv.inv_warehouse_sk AS warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory_qty,
        COUNT(*) AS inventory_txn
    FROM inventory inv
    GROUP BY inv.inv_date_sk, inv.inv_warehouse_sk
)
SELECT
    s.s_store_name,
    d.d_year,
    p_ss.p_promo_name,
    SUM(ssa.total_store_sales_net_paid) AS total_store_sales,
    SUM(csa.total_catalog_sales_net_paid) AS total_catalog_sales,
    SUM(cra.total_catalog_return_amount) AS total_catalog_returns,
    SUM(sra.total_store_return_amt) AS total_store_returns,
    SUM(wra.total_web_return_amt) AS total_web_returns,
    SUM(ia.total_inventory_qty) AS total_inventory_quantity,
    (SUM(ssa.total_store_sales_net_paid) + SUM(csa.total_catalog_sales_net_paid) -
     (SUM(cra.total_catalog_return_amount) + SUM(sra.total_store_return_amt) + SUM(wra.total_web_return_amt))) AS net_revenue
FROM store_sales_agg ssa
JOIN store s ON s.s_store_sk = ssa.store_sk
JOIN date_dim d ON d.d_date_sk = ssa.sold_date_sk
JOIN promotion p_ss ON p_ss.p_promo_sk = ssa.promo_sk
JOIN household_demographics hd ON hd.hd_demo_sk = ssa.hd_demo_sk
JOIN income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN customer_address ca ON ca.ca_address_sk = ssa.address_sk
LEFT JOIN catalog_sales_agg csa
    ON csa.sold_date_sk = d.d_date_sk
   AND csa.promo_sk = p_ss.p_promo_sk
LEFT JOIN call_center cc ON cc.cc_call_center_sk = csa.call_center_sk
LEFT JOIN warehouse w_cs ON w_cs.w_warehouse_sk = csa.warehouse_sk
LEFT JOIN promotion p_cs ON p_cs.p_promo_sk = csa.promo_sk
LEFT JOIN catalog_returns_agg cra ON cra.returned_date_sk = d.d_date_sk
LEFT JOIN reason r_cr ON r_cr.r_reason_sk = cra.reason_sk
LEFT JOIN store_returns_agg sra
    ON sra.returned_date_sk = d.d_date_sk
   AND sra.store_sk = s.s_store_sk
LEFT JOIN reason r_sr ON r_sr.r_reason_sk = sra.reason_sk
LEFT JOIN web_returns_agg wra ON wra.returned_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_web_page_sk = wra.web_page_sk
LEFT JOIN reason r_wr ON r_wr.r_reason_sk = wra.reason_sk
LEFT JOIN inventory_agg ia ON ia.inv_date_sk = d.d_date_sk
LEFT JOIN warehouse w_inv ON w_inv.w_warehouse_sk = ia.warehouse_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND p_ss.p_discount_active = 'Y'
GROUP BY GROUPING SETS (
    (s.s_store_name, d.d_year, p_ss.p_promo_name),
    (s.s_store_name, d.d_year),
    (s.s_store_name),
    ()
)
ORDER BY s.s_store_name, d.d_year, p_ss.p_promo_name
LIMIT 100
