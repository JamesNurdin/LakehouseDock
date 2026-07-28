WITH base AS (
    SELECT
        d_cs.d_year,
        i.i_category,
        s.s_state,
        cc.cc_market_manager,
        p.p_promo_name,
        cs.cs_ext_sales_price        AS catalog_sales_price,
        ss.ss_ext_sales_price        AS store_sales_price,
        cr.cr_return_amount          AS cr_return_amount,
        sr.sr_return_amt             AS sr_return_amt,
        cd_bill.cd_dep_count         AS cd_dep_count,
        cs.cs_order_number           AS cs_order_number,
        ss.ss_ticket_number          AS ss_ticket_number
    FROM catalog_sales cs
    JOIN date_dim d_cs               ON cs.cs_sold_date_sk   = d_cs.d_date_sk
    JOIN time_dim t_cs               ON cs.cs_sold_time_sk   = t_cs.t_time_sk
    JOIN item i                      ON cs.cs_item_sk        = i.i_item_sk
    JOIN promotion p                 ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN call_center cc              ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp             ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w                 ON cs.cs_warehouse_sk   = w.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    
    -- store sales and related dimensions
    JOIN store_sales ss               ON i.i_item_sk         = ss.ss_item_sk
    JOIN store s                      ON ss.ss_store_sk      = s.s_store_sk
    JOIN date_dim d_ss                ON ss.ss_sold_date_sk  = d_ss.d_date_sk
    JOIN time_dim t_ss                ON ss.ss_sold_time_sk  = t_ss.t_time_sk
    
    -- store returns (left join, may be missing)
    LEFT JOIN store_returns sr       ON ss.ss_ticket_number = sr.sr_ticket_number
                                   AND ss.ss_item_sk       = sr.sr_item_sk
    LEFT JOIN date_dim d_sr          ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr          ON sr.sr_return_time_sk   = t_sr.t_time_sk
    
    -- catalog returns (left join, may be missing)
    LEFT JOIN catalog_returns cr    ON cs.cs_order_number = cr.cr_order_number
                                   AND cs.cs_item_sk      = cr.cr_item_sk
    LEFT JOIN date_dim d_cr          ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr          ON cr.cr_returned_time_sk = t_cr.t_time_sk
    
    WHERE d_cs.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND cc.cc_market_manager = 'John Doe'
      AND p.p_discount_active = 'Y'
      AND cd_bill.cd_dep_count > 3
      AND NOT EXISTS (
          SELECT 1 FROM catalog_returns cr2
          WHERE cr2.cr_order_number = cs.cs_order_number
            AND cr2.cr_return_amount > 0
      )
),
aggregated AS (
    SELECT
        d_year,
        i_category,
        s_state,
        cc_market_manager,
        p_promo_name,
        SUM(catalog_sales_price) AS total_catalog_sales,
        SUM(store_sales_price)    AS total_store_sales,
        SUM(catalog_sales_price) + SUM(store_sales_price) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS catalog_orders,
        COUNT(DISTINCT ss_ticket_number) AS store_transactions,
        AVG(cr_return_amount)    AS avg_catalog_return,
        SUM(sr_return_amt)       AS total_store_returns
    FROM base
    GROUP BY d_year, i_category, s_state, cc_market_manager, p_promo_name
)
SELECT
    a.d_year,
    a.i_category,
    a.s_state,
    a.cc_market_manager,
    a.p_promo_name,
    a.total_catalog_sales,
    a.total_store_sales,
    a.total_sales,
    a.catalog_orders,
    a.store_transactions,
    a.avg_catalog_return,
    a.total_store_returns,
    ROW_NUMBER() OVER (PARTITION BY a.s_state ORDER BY a.total_sales DESC) AS state_rank,
    SUM(a.total_sales) OVER (PARTITION BY a.s_state ORDER BY a.total_sales ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_state,
    (SELECT SUM(p_sub.p_cost)
       FROM promotion p_sub
      WHERE p_sub.p_start_date_sk BETWEEN 2450000 AND 2455000) AS total_promo_cost
FROM aggregated a
ORDER BY a.total_sales DESC
LIMIT 100
