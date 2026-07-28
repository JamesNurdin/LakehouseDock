WITH base AS (
    SELECT
        cp.cp_department,
        i.i_category,
        w.w_state,
        sm.sm_carrier,
        td.t_hour,
        cs.cs_net_profit               AS catalog_profit,
        ss.ss_net_profit               AS store_profit,
        cr.cr_net_loss                 AS catalog_return_loss,
        sr.sr_net_loss                 AS store_return_loss,
        inv.inv_quantity_on_hand
    FROM tpcds.catalog_sales cs
    JOIN tpcds.time_dim td               ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.item i                    ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.catalog_returns cr       ON cr.cr_order_number = cs.cs_order_number
                                         AND cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.reason r                  ON cr.cr_reason_sk = r.r_reason_sk
    JOIN tpcds.inventory inv             ON inv.inv_item_sk = i.i_item_sk
                                         AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.store_sales ss           ON ss.ss_ticket_number = cs.cs_order_number
                                         AND ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store_returns sr          ON sr.sr_ticket_number = ss.ss_ticket_number
                                         AND sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer_address ca_bill   ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship   ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN tpcds.customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
    JOIN tpcds.customer_address ca_store_ret ON sr.sr_addr_sk = ca_store_ret.ca_address_sk
    WHERE cp.cp_department = 'Electronics'
      AND w.w_state = 'CA'
      AND sm.sm_carrier = 'FEDEX'
      AND r.r_reason_desc LIKE '%damage%'
      AND td.t_hour BETWEEN 8 AND 12
      AND inv.inv_quantity_on_hand > 100
      AND sr.sr_return_quantity > 5
),
agg AS (
    SELECT
        cp_department,
        i_category,
        t_hour,
        SUM(catalog_profit)            AS sum_catalog_profit,
        SUM(store_profit)              AS sum_store_profit,
        SUM(catalog_return_loss)       AS sum_catalog_return_loss,
        SUM(store_return_loss)         AS sum_store_return_loss,
        SUM(catalog_profit + store_profit - catalog_return_loss - store_return_loss) AS total_profit,
        CASE WHEN SUM(catalog_profit + store_profit - catalog_return_loss - store_return_loss) > 10000
             THEN 'High' ELSE 'Low' END AS profit_level
    FROM base
    GROUP BY ROLLUP (cp_department, i_category, t_hour)
)
SELECT
    cp_department,
    i_category,
    t_hour,
    total_profit,
    profit_level,
    AVG(total_profit) OVER (PARTITION BY cp_department)           AS avg_profit_by_dept,
    ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_profit DESC) AS profit_rank
FROM agg
WHERE total_profit IS NOT NULL
ORDER BY cp_department, i_category, t_hour
LIMIT 100
