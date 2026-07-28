/*
  Goal: Rank product categories by total profit (catalog sales + store sales – catalog returns – web returns) for the years 2000‑2002, limited to items from selected manufacturers, TV promotions, and stores in CA. The query joins all 16 TPC‑DS tables using only the defined join rules, applies four filter predicates, uses a CASE expression to flag high profit, aggregates with ROLLUP, and ranks rows per year.
*/
WITH joined_data AS (
    SELECT
        d.d_year,
        i.i_category,
        s.s_state,
        cs.cs_net_profit,
        ss.ss_net_profit,
        cr.cr_net_loss,
        wr.wr_net_loss,
        p.p_channel_tv,
        i.i_manufact_id
    FROM catalog_sales cs
    JOIN date_dim d                     ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
    JOIN store_sales ss                ON ss.ss_sold_date_sk = d.d_date_sk
                                      AND ss.ss_item_sk = i.i_item_sk
    JOIN store s                       ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_returns cr           ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = i.i_item_sk
    JOIN reason r_cr                   ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN inventory inv                 ON inv.inv_date_sk = d.d_date_sk
                                      AND inv.inv_item_sk = i.i_item_sk
    JOIN web_returns wr               ON wr.wr_item_sk = i.i_item_sk
                                      AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp                   ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr                   ON wr.wr_reason_sk = r_wr.r_reason_sk
    /* customer related joins (required to satisfy join rules) */
    JOIN customer c_bill               ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer c_ship               ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN customer c_refund             ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_address ca_refund    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
    JOIN customer_demographics cd_refund ON cr.cr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    JOIN customer c_returning          ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_address ca_returning ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN customer c_wr_refund          ON wr.wr_refunded_customer_sk = c_wr_refund.c_customer_sk
    JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
    JOIN customer_demographics cd_wr_refund ON wr.wr_refunded_cdemo_sk = cd_wr_refund.cd_demo_sk
    JOIN customer c_wr_returning       ON wr.wr_returning_customer_sk = c_wr_returning.c_customer_sk
    JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_manufact_id IN (212, 364)
      AND p.p_channel_tv = 'Y'
      AND s.s_state = 'CA'
),
agg AS (
    SELECT
        d_year,
        i_category,
        s_state,
        SUM(cs_net_profit)        AS catalog_net_profit,
        SUM(ss_net_profit)        AS store_net_profit,
        SUM(cr_net_loss)          AS catalog_return_loss,
        SUM(wr_net_loss)          AS web_return_loss
    FROM joined_data
    GROUP BY ROLLUP (d_year, i_category, s_state)
)
SELECT
    d_year,
    i_category,
    s_state,
    catalog_net_profit,
    store_net_profit,
    catalog_return_loss,
    web_return_loss,
    (catalog_net_profit + store_net_profit - catalog_return_loss - web_return_loss) AS total_profit,
    CASE
        WHEN (catalog_net_profit + store_net_profit - catalog_return_loss - web_return_loss) > 50000 THEN 'High'
        ELSE 'Low'
    END AS profit_flag,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY (catalog_net_profit + store_net_profit - catalog_return_loss - web_return_loss) DESC) AS profit_rank
FROM agg
ORDER BY d_year, i_category, s_state, profit_rank
LIMIT 100
