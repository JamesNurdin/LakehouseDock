WITH sub_a AS (
    SELECT
        d_ss.d_year AS year,
        s.s_state AS state,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    INNER JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    INNER JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    INNER JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    INNER JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    INNER JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_ss.d_date_sk
        AND cs.cs_sold_time_sk = t_ss.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    INNER JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    INNER JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    INNER JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    INNER JOIN web_page wp ON wp.wp_creation_date_sk = d_ss.d_date_sk
    INNER JOIN web_site ws ON ws.web_open_date_sk = d_ss.d_date_sk
    INNER JOIN inventory inv ON inv.inv_date_sk = d_ss.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d_ss.d_year BETWEEN 2000 AND 2002
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND cc.cc_mkt_id IN (1, 3)
      AND ws.web_mkt_class LIKE '%social%'
    GROUP BY ROLLUP (d_ss.d_year, s.s_state, i.i_category)
    HAVING SUM(ss.ss_net_profit) > 0
),
sub_b AS (
    SELECT
        d_ss.d_year AS year,
        s.s_state AS state,
        i.i_category AS category,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(inv.inv_quantity_on_hand) AS inventory_qty
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN date_dim d_ss ON ss.ss_sold_date_sk = d_ss.d_date_sk
    INNER JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    INNER JOIN item i ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    INNER JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    INNER JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    INNER JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
    INNER JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    INNER JOIN date_dim d_sr ON sr.sr_returned_date_sk = d_sr.d_date_sk
    INNER JOIN time_dim t_sr ON sr.sr_return_time_sk = t_sr.t_time_sk
    INNER JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_ss.d_date_sk
        AND cs.cs_sold_time_sk = t_ss.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
    INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = i.i_item_sk
    INNER JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
    INNER JOIN time_dim t_cr ON cr.cr_returned_time_sk = t_cr.t_time_sk
    INNER JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    INNER JOIN web_page wp ON wp.wp_creation_date_sk = d_ss.d_date_sk
    INNER JOIN web_site ws ON ws.web_open_date_sk = d_ss.d_date_sk
    INNER JOIN inventory inv ON inv.inv_date_sk = d_ss.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d_ss.d_year BETWEEN 2000 AND 2002
      AND i.i_brand = 'Brand#34'
      AND s.s_state = 'TX'
      AND cc.cc_mkt_id IN (2, 4)
      AND ws.web_mkt_class LIKE '%new%'
    GROUP BY ROLLUP (d_ss.d_year, s.s_state, i.i_category)
    HAVING SUM(ss.ss_net_profit) > 0
)
SELECT
    year,
    state,
    category,
    store_sales_profit,
    catalog_sales_profit,
    store_sales_profit + catalog_sales_profit AS total_profit,
    inventory_qty,
    ROW_NUMBER() OVER (PARTITION BY year ORDER BY (store_sales_profit + catalog_sales_profit) DESC) AS profit_rank,
    CASE WHEN (store_sales_profit + catalog_sales_profit) > 10000 THEN 'High' ELSE 'Medium' END AS profit_level
FROM (
    SELECT * FROM sub_a
    UNION
    SELECT * FROM sub_b
) u
ORDER BY year, profit_rank
LIMIT 100
