/* Goal: Rank catalog pages by net profit for male customers with monthly catalogs, while analyzing associated store sales and returns, applying multiple filters, and using window functions and correlated subqueries for risk assessment. */
SELECT
    cp.cp_department,
    cp.cp_type,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_credit_rating,
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship_tax,
    ss.ss_net_paid,
    sr.sr_return_amt,
    sr.sr_net_loss,
    td_cs.t_hour AS sale_hour,
    td_ss.t_hour AS store_sale_hour,
    td_sr.t_hour AS return_hour,
    (
        SELECT avg(cs2.cs_net_profit)
        FROM catalog_sales cs2
        WHERE cs2.cs_catalog_page_sk = cs.cs_catalog_page_sk
    ) AS avg_page_net_profit,
    (
        SELECT avg(sr_all.sr_return_amt)
        FROM store_returns sr_all
    ) AS overall_avg_return_amt,
    CASE WHEN EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = sr.sr_customer_sk
          AND sr2.sr_return_amt > 500
    ) THEN 'HIGH' ELSE 'LOW' END AS return_risk_flag,
    RANK() OVER (PARTITION BY cp.cp_department ORDER BY cs.cs_net_profit DESC) AS dept_profit_rank
FROM catalog_sales cs
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN time_dim td_cs
    ON cs.cs_sold_time_sk = td_cs.t_time_sk
JOIN store_sales ss
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN time_dim td_ss
    ON ss.ss_sold_time_sk = td_ss.t_time_sk
JOIN store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
   AND sr.sr_item_sk = ss.ss_item_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr
    ON sr.sr_return_time_sk = td_sr.t_time_sk
WHERE
    cd.cd_gender = 'M'
    AND cp.cp_type = 'monthly'
    AND cs.cs_net_paid_inc_ship_tax > 500
    AND td_ss.t_hour BETWEEN 9 AND 17
    AND sr.sr_return_quantity > 0
    AND cd.cd_credit_rating = 'Good'
ORDER BY cp.cp_department, dept_profit_rank
LIMIT 100
