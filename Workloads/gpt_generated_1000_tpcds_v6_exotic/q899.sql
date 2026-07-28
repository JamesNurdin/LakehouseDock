/*
  Goal: Compute net profit per store for the year 2001, aggregating sales and all types of returns, while filtering on high tax rates, preferred customers, active promotions, a specific return reason, and positive inventory levels. The query joins all 16 selected TPC‑DS tables, aggregates in a CTE, applies additional HAVING filters, computes a derived net profit, ranks stores by this profit, orders the result, and limits to the top 100.
*/
WITH joined_data AS (
    SELECT
        s.s_store_name               AS s_store_name,
        d.d_year                     AS d_year,
        ws.ws_net_profit             AS ws_net_profit,
        sr.sr_net_loss               AS sr_net_loss,
        cr.cr_net_loss               AS cr_net_loss,
        wr.wr_net_loss               AS wr_net_loss,
        i.inv_quantity_on_hand      AS inv_quantity_on_hand,
        cc.cc_tax_percentage         AS cc_tax_percentage,
        c.c_preferred_cust_flag     AS c_preferred_cust_flag,
        p.p_discount_active          AS p_discount_active,
        r.r_reason_desc              AS r_reason_desc
    FROM store s
    JOIN store_returns sr
      ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
      ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
      ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN reason r
      ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr
      ON cr.cr_returned_date_sk = d.d_date_sk
     AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
      ON ws.ws_sold_date_sk = d.d_date_sk
     AND ws.ws_sold_time_sk = t.t_time_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr
      ON wr.wr_returned_date_sk = d.d_date_sk
     AND wr.wr_returned_time_sk = t.t_time_sk
     AND wr.wr_order_number = ws.ws_order_number
    JOIN inventory i
      ON i.inv_date_sk = d.d_date_sk
     AND i.inv_warehouse_sk = w.w_warehouse_sk
    -- additional reason joins to satisfy foreign‑key rules
    JOIN reason r_cr
      ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN reason r_wr
      ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2001
      AND cc.cc_tax_percentage > 0.05
      AND c.c_preferred_cust_flag = 'Y'
      AND p.p_discount_active = 'Y'
      AND r.r_reason_desc = 'Package was damaged'
      AND i.inv_quantity_on_hand > 0
),
aggregated AS (
    SELECT
        s_store_name,
        d_year,
        SUM(ws_net_profit)                                    AS total_sales_profit,
        SUM(sr_net_loss)                                      AS total_store_loss,
        SUM(cr_net_loss)                                      AS total_catalog_loss,
        SUM(wr_net_loss)                                      AS total_web_loss,
        SUM(inv_quantity_on_hand)                             AS total_inventory,
        AVG(cc_tax_percentage)                                AS avg_tax_pct,
        COUNT(*)                                              AS txn_count,
        SUM(CASE WHEN c_preferred_cust_flag = 'Y' THEN 1 ELSE 0 END) AS preferred_cnt,
        MAX(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END)       AS discount_active_flag
    FROM joined_data
    GROUP BY s_store_name, d_year
    HAVING SUM(ws_net_profit) > 10000
       AND (SUM(sr_net_loss) + SUM(cr_net_loss) + SUM(wr_net_loss)) < 50000
       AND AVG(cc_tax_percentage) > 0.06
       AND COUNT(*) > 10
)
SELECT
    s_store_name,
    d_year,
    total_sales_profit,
    total_store_loss,
    total_catalog_loss,
    total_web_loss,
    total_sales_profit - (total_store_loss + total_catalog_loss + total_web_loss) AS net_profit,
    total_inventory,
    avg_tax_pct,
    preferred_cnt,
    discount_active_flag,
    RANK() OVER (ORDER BY (total_sales_profit - (total_store_loss + total_catalog_loss + total_web_loss)) DESC) AS profit_rank
FROM aggregated
ORDER BY net_profit DESC
LIMIT 100
