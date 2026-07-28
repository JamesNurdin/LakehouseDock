WITH sales_data AS (
    SELECT
        cs.cs_sold_date_sk,
        d.d_year AS d_year,
        cs.cs_item_sk,
        i.i_product_name,
        i.i_category,
        i.i_color,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        cp.cp_department,
        w.w_warehouse_name,
        w.w_state,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        cd.cd_purchase_estimate,
        hd.hd_buy_potential,
        ib.ib_upper_bound,
        -- store sales fields
        ss.ss_sold_date_sk AS ss_sold_date_sk,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        s.s_store_name,
        -- web sales fields
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        wp.wp_url,
        -- return fields
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        r.r_reason_desc,
        -- scalar subquery: average catalog return amount for the same order
        (SELECT avg(cr2.cr_return_amount)
         FROM catalog_returns cr2
         WHERE cr2.cr_order_number = cs.cs_order_number) AS avg_catalog_return_amount,
        -- lateral subquery: total inventory on hand for the item
        inv_agg.total_inventory
    FROM catalog_sales cs
    JOIN date_dim d                ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i                    ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c                ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca       ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w               ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr   ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r             ON cr.cr_reason_sk = r.r_reason_sk
    -- store sales and related dimensions
    LEFT JOIN store_sales ss        ON ss.ss_ticket_number = cs.cs_order_number
    LEFT JOIN date_dim d_ss         ON ss.ss_sold_date_sk = d_ss.d_date_sk
    LEFT JOIN time_dim t_ss         ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr     ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r_sr           ON sr.sr_reason_sk = r_sr.r_reason_sk
    -- web sales and related dimensions
    LEFT JOIN web_sales ws          ON ws.ws_order_number = cs.cs_order_number
    LEFT JOIN date_dim d_ws         ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN time_dim t_ws         ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr       ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr           ON wr.wr_reason_sk = r_wr.r_reason_sk
    -- lateral join to inventory (allowed by inv_item_sk = i_item_sk)
    CROSS JOIN LATERAL (
        SELECT sum(inv_quantity_on_hand) AS total_inventory
        FROM inventory inv
        WHERE inv.inv_item_sk = i.i_item_sk
    ) inv_agg
    WHERE d.d_year = 2001
      AND i.i_color = 'Red'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND r.r_reason_desc IS NOT NULL
)
SELECT
    d_year,
    i_category,
    i_product_name,
    SUM(cs_ext_sales_price)          AS total_sales,
    SUM(cs_net_profit)               AS catalog_profit,
    SUM(ss_net_profit)               AS store_profit,
    SUM(ws_net_profit)               AS web_profit,
    SUM(total_inventory)             AS total_inventory_on_hand,
    CASE WHEN SUM(cs_net_profit) > 5000 THEN 'High' ELSE 'Low' END AS profit_level,
    RANK() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_profit) DESC) AS profit_rank,
    GROUPING(d_year)                 AS grp_year,
    GROUPING(i_category)             AS grp_category
FROM sales_data
GROUP BY ROLLUP (d_year, i_category, i_product_name)
HAVING SUM(cs_ext_sales_price) > 0
ORDER BY d_year, i_category, profit_rank
LIMIT 100
