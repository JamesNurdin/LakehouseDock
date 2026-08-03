WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        s.s_store_id,
        s.s_state,
        c.c_customer_id,
        cd.cd_gender,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        ib.ib_lower_bound,
        cc.cc_class,
        cp.cp_catalog_number,
        cp.cp_type,
        cs.cs_order_number,
        cs.cs_net_paid AS cs_net_paid,
        cr.cr_return_amount,
        cr.cr_net_loss,
        r.r_reason_desc,
        w.w_warehouse_id,
        inv.inv_quantity_on_hand,
        wr.wr_return_amt,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_returns wr ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE s.s_state = 'CA'
      AND cc.cc_class = 'Corporate'
      AND cp.cp_catalog_number IN (5, 15)
      AND ib.ib_upper_bound >= 150000
),
agg AS (
    SELECT
        s_store_id,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ss_ticket_number) AS txn_count,
        MIN(cs_order_number) AS sample_order_number,
        CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag,
        AVG(CASE WHEN ib_upper_bound > 150000 THEN ss_quantity ELSE 0 END) AS avg_qty_high_income
    FROM base
    GROUP BY s_store_id
    HAVING COUNT(*) > 10
),
union_set AS (
    SELECT s_store_id FROM agg WHERE profit_flag = 'Profitable'
    UNION DISTINCT
    SELECT s_store_id FROM agg WHERE profit_flag = 'Loss'
),
filtered_set AS (
    SELECT s_store_id FROM union_set
    EXCEPT
    SELECT s_store_id FROM agg WHERE txn_count > 100
),
full_join AS (
    SELECT
        ss.ss_ticket_number,
        s.s_store_id,
        ss.ss_net_paid,
        s.s_state
    FROM store_sales ss
    FULL OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
)
SELECT
    f.s_store_id,
    a.total_store_profit,
    a.profit_flag,
    CASE WHEN a.profit_flag = 'Profitable' THEN 'Good' ELSE 'Bad' END AS assessment
FROM filtered_set f
JOIN agg a ON f.s_store_id = a.s_store_id
JOIN full_join fj ON fj.s_store_id = f.s_store_id
WHERE EXISTS (
    SELECT 1 FROM catalog_returns cr WHERE cr.cr_order_number = a.sample_order_number
)
ORDER BY a.total_store_profit DESC
LIMIT 100
