WITH sales_agg AS (
    SELECT
        cp.cp_department,
        sm.sm_type AS ship_mode_type,
        hd.hd_buy_potential,
        w.w_state,
        cs.cs_sold_date_sk AS sold_date,
        SUM(cs.cs_net_paid_inc_tax) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451088
      AND cp.cp_department = 'DEPARTMENT'
    GROUP BY cp.cp_department, sm.sm_type, hd.hd_buy_potential, w.w_state, cs.cs_sold_date_sk
),
returns_agg AS (
    SELECT
        cp.cp_department,
        sm.sm_type AS ship_mode_type,
        hd.hd_buy_potential,
        w.w_state,
        cr.cr_returned_date_sk AS return_date,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS num_returns,
        SUM(cr.cr_return_quantity) AS total_return_quantity
    FROM catalog_returns cr
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2450815 AND 2451088
      AND cp.cp_department = 'DEPARTMENT'
    GROUP BY cp.cp_department, sm.sm_type, hd.hd_buy_potential, w.w_state, cr.cr_returned_date_sk
)
SELECT
    s.cp_department,
    s.ship_mode_type,
    s.hd_buy_potential,
    s.w_state,
    s.sold_date,
    s.total_sales,
    s.total_profit,
    s.total_discount,
    s.num_orders,
    s.total_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_net_loss, 0) AS total_return_loss,
    s.total_sales - COALESCE(r.total_return_amount, 0) AS net_sales_after_returns,
    RANK() OVER (PARTITION BY s.w_state ORDER BY (s.total_profit - COALESCE(r.total_net_loss, 0)) DESC) AS profit_rank_state
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.cp_department = r.cp_department
   AND s.ship_mode_type = r.ship_mode_type
   AND s.hd_buy_potential = r.hd_buy_potential
   AND s.w_state = r.w_state
   AND s.sold_date = r.return_date
WHERE s.total_sales > 1000
ORDER BY s.w_state, profit_rank_state
LIMIT 100
