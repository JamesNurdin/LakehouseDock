WITH cat_agg AS (
    SELECT
        p_cat.p_promo_name AS promo_name,
        t_cs.t_hour AS hour_of_day,
        SUM(cs.cs_net_paid) AS cat_net_paid,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        COUNT(DISTINCT c.c_customer_sk) AS cat_distinct_customers,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS cat_return_amount,
        SUM(COALESCE(cr.cr_net_loss, 0)) AS cat_return_net_loss,
        SUM(COALESCE(inv.inv_quantity_on_hand, 0)) AS inventory_qty
    FROM catalog_sales cs
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
    JOIN call_center cc1 ON cs.cs_call_center_sk = cc1.cc_call_center_sk
    JOIN ship_mode sm1 ON cs.cs_ship_mode_sk = sm1.sm_ship_mode_sk
    JOIN warehouse w1 ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN call_center cc2 ON cr.cr_call_center_sk = cc2.cc_call_center_sk
    LEFT JOIN ship_mode sm2 ON cr.cr_ship_mode_sk = sm2.sm_ship_mode_sk
    LEFT JOIN warehouse w2 ON cr.cr_warehouse_sk = w2.w_warehouse_sk
    LEFT JOIN inventory inv ON inv.inv_warehouse_sk = w1.w_warehouse_sk
    GROUP BY p_cat.p_promo_name, t_cs.t_hour
),
store_agg AS (
    SELECT
        p_store.p_promo_name AS promo_name,
        t_ss.t_hour AS hour_of_day,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_distinct_customers,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amount,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_return_net_loss
    FROM store_sales ss
    JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    JOIN promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    GROUP BY p_store.p_promo_name, t_ss.t_hour
),
web_agg AS (
    SELECT
        NULL AS promo_name,
        t_wr.t_hour AS hour_of_day,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_return_net_loss,
        COUNT(DISTINCT wr.wr_refunded_customer_sk) AS web_distinct_customers
    FROM web_returns wr
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    GROUP BY t_wr.t_hour
)
SELECT
    COALESCE(ca.promo_name, sa.promo_name) AS promo_name,
    COALESCE(ca.hour_of_day, sa.hour_of_day, wa.hour_of_day) AS hour_of_day,
    COALESCE(ca.cat_net_paid, 0) + COALESCE(sa.store_net_paid, 0) AS total_net_paid,
    COALESCE(ca.cat_net_profit, 0) + COALESCE(sa.store_net_profit, 0) AS total_net_profit,
    COALESCE(ca.cat_return_amount, 0) + COALESCE(sa.store_return_amount, 0) + COALESCE(wa.web_return_amount, 0) AS total_return_amount,
    COALESCE(ca.cat_return_net_loss, 0) + COALESCE(sa.store_return_net_loss, 0) + COALESCE(wa.web_return_net_loss, 0) AS total_return_net_loss,
    COALESCE(ca.cat_distinct_customers, 0) + COALESCE(sa.store_distinct_customers, 0) + COALESCE(wa.web_distinct_customers, 0) AS total_distinct_customers,
    CASE WHEN (COALESCE(ca.cat_net_profit, 0) + COALESCE(sa.store_net_profit, 0) -
               COALESCE(ca.cat_return_net_loss, 0) - COALESCE(sa.store_return_net_loss, 0) -
               COALESCE(wa.web_return_net_loss, 0)) > 0
         THEN 'Profit' ELSE 'Loss' END AS overall_profit_flag,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(ca.cat_net_paid, 0) + COALESCE(sa.store_net_paid, 0)) DESC) AS sales_rank
FROM cat_agg ca
FULL OUTER JOIN store_agg sa
    ON ca.promo_name = sa.promo_name AND ca.hour_of_day = sa.hour_of_day
FULL OUTER JOIN web_agg wa
    ON COALESCE(ca.hour_of_day, sa.hour_of_day) = wa.hour_of_day
ORDER BY total_net_paid DESC
LIMIT 100
