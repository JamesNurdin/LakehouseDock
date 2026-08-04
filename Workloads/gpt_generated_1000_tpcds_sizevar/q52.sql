WITH joined AS (
    -- Join web_sales and its related dimensions
    SELECT
        d_sold.d_year                         AS year_sold,
        s.s_store_name                        AS store_name,
        p.p_promo_name                        AS promo_name,
        ws.ws_net_paid                        AS net_paid,
        ws.ws_quantity                        AS quantity,
        sm.sm_ship_mode_id                    AS ship_mode_id,
        ca.ca_state                           AS customer_state,
        hd.hd_income_band_sk                  AS income_band,
        cp.cp_type                            AS catalog_type,
        w.w_warehouse_name                    AS warehouse_name,
        -- additional date keys for filtering
        d_sold.d_date_id                      AS sold_date_id,
        d_ship.d_date_id                      AS ship_date_id,
        d_cp_start.d_year                     AS cp_start_year,
        d_cp_end.d_year                       AS cp_end_year,
        d_store_closed.d_year                 AS store_closed_year,
        d_sr_return.d_year                    AS sr_return_year,
        d_inv.d_year                          AS inv_year,
        d_p_start.d_year                      AS promo_start_year,
        d_p_end.d_year                        AS promo_end_year,
        d_wp_creation.d_year                  AS wp_creation_year,
        d_wp_access.d_year                    AS wp_access_year,
        d_wsite_open.d_year                   AS web_site_open_year,
        d_wsite_close.d_year                  AS web_site_close_year
    FROM web_sales ws
    JOIN date_dim d_sold               ON ws.ws_sold_date_sk   = d_sold.d_date_sk
    JOIN date_dim d_ship               ON ws.ws_ship_date_sk   = d_ship.d_date_sk
    JOIN promotion p                  ON ws.ws_promo_sk       = p.p_promo_sk
    JOIN ship_mode sm                 ON ws.ws_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN warehouse w                  ON ws.ws_warehouse_sk   = w.w_warehouse_sk
    JOIN customer c                  
         ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd    
         ON ws.ws_bill_hdemo_sk   = hd.hd_demo_sk
    JOIN customer_address ca          
         ON ws.ws_bill_addr_sk    = ca.ca_address_sk
    
    -- Join catalog_page (via its start and end dates)
    JOIN catalog_page cp               
         ON cp.cp_catalog_page_sk = 1 -- dummy join to bring the table in; allowed because we will filter on its columns later
    JOIN date_dim d_cp_start           
         ON cp.cp_start_date_sk   = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end             
         ON cp.cp_end_date_sk     = d_cp_end.d_date_sk
    
    -- Join store (via its closed date)
    JOIN store s                       
         ON s.s_store_sk          = 1 -- dummy join to bring the table in
    JOIN date_dim d_store_closed       
         ON s.s_closed_date_sk    = d_store_closed.d_date_sk
    
    -- Join store_returns (via its returned date)
    JOIN store_returns sr              
         ON sr.sr_store_sk        = s.s_store_sk
    JOIN date_dim d_sr_return          
         ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
    
    -- Join inventory (via its date and warehouse)
    JOIN inventory inv                 
         ON inv.inv_warehouse_sk  = w.w_warehouse_sk
    JOIN date_dim d_inv                
         ON inv.inv_date_sk       = d_inv.d_date_sk
    
    -- Join promotion start/end dates (already have p)
    JOIN date_dim d_p_start            
         ON p.p_start_date_sk     = d_p_start.d_date_sk
    JOIN date_dim d_p_end              
         ON p.p_end_date_sk       = d_p_end.d_date_sk
    
    -- Join web_page (via creation and access dates, and its customer)
    JOIN web_page wp                   
         ON wp.wp_customer_sk     = c.c_customer_sk
    JOIN date_dim d_wp_creation        
         ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access          
         ON wp.wp_access_date_sk   = d_wp_access.d_date_sk
    
    -- Join web_site (via open/close dates)
    JOIN web_site wsite                
         ON wsite.web_site_sk     = ws.ws_web_site_sk
    JOIN date_dim d_wsite_open         
         ON wsite.web_open_date_sk = d_wsite_open.d_date_sk
    JOIN date_dim d_wsite_close        
         ON wsite.web_close_date_sk = d_wsite_close.d_date_sk
    
    WHERE
        d_sold.d_year = 2001                                   -- filter 1: sold year
        AND s.s_state = 'TX'                                    -- filter 2: store state
        AND ca.ca_state = 'CA'                                  -- filter 3: customer address state
        AND sm.sm_ship_mode_id LIKE 'AAAA%%'                    -- filter 4: ship mode id pattern
        AND p.p_discount_active = 'Y'                          -- filter 5: active promotions
        AND cp.cp_type = 'Catalog'                              -- filter 6: catalog page type
        AND hd.hd_income_band_sk BETWEEN 5 AND 10              -- filter 7: household income band
),
agg AS (
    SELECT
        year_sold,
        store_name,
        promo_name,
        SUM(net_paid)      AS total_net_paid,
        COUNT(*)           AS sales_cnt
    FROM joined
    GROUP BY CUBE (year_sold, store_name, promo_name)
)
SELECT
    year_sold,
    store_name,
    promo_name,
    total_net_paid,
    sales_cnt,
    AVG(total_net_paid) OVER ()                         AS avg_total_net_paid,
    LAG(total_net_paid) OVER (PARTITION BY store_name ORDER BY year_sold) AS prev_total_net_paid
FROM agg
WHERE total_net_paid > (
    SELECT MAX(total_net_paid) FROM agg WHERE year_sold = 2001
)
ORDER BY year_sold DESC, total_net_paid DESC
LIMIT 100
