WITH aggregated AS (
    SELECT
        i.i_item_id                     AS item_id,
        i.i_product_name                AS product_name,
        i.i_brand                       AS brand,
        d_cs.d_year                     AS year,
        SUM(COALESCE(cs.cs_net_profit, 0))   AS total_catalog_profit,
        SUM(COALESCE(ws.ws_net_profit, 0))   AS total_web_profit,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
        SUM(COALESCE(sr.sr_return_amt, 0))   AS total_store_return_amount,
        SUM(COALESCE(wr.wr_return_amt, 0))   AS total_web_return_amount
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs
        ON cs.cs_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cs.cs_item_sk = cr.cr_item_sk
        AND cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
    LEFT JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    LEFT JOIN time_dim t_cr
        ON cr.cr_returned_time_sk = t_cr.t_time_sk
    LEFT JOIN store_returns sr
        ON i.i_item_sk = sr.sr_item_sk
    LEFT JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    LEFT JOIN web_sales ws
        ON cs.cs_item_sk = ws.ws_item_sk
        AND cs.cs_sold_date_sk = ws.ws_sold_date_sk
        AND cs.cs_sold_time_sk = ws.ws_sold_time_sk
        AND ws.ws_sold_date_sk = d_cs.d_date_sk
        AND ws.ws_sold_time_sk = t_cs.t_time_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN promotion p_ws
        ON ws.ws_promo_sk = p_ws.p_promo_sk
        AND p_ws.p_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
        AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN date_dim d_wr
        ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr
        ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    LEFT JOIN web_page wp_wr
        ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
    LEFT JOIN date_dim d_page_start
        ON cp.cp_start_date_sk = d_page_start.d_date_sk
    LEFT JOIN date_dim d_page_end
        ON cp.cp_end_date_sk = d_page_end.d_date_sk
    LEFT JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    LEFT JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    LEFT JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    LEFT JOIN date_dim d_site_open
        ON we.web_open_date_sk = d_site_open.d_date_sk
    LEFT JOIN date_dim d_site_close
        ON we.web_close_date_sk = d_site_close.d_date_sk
    LEFT JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    WHERE
        d_cs.d_year = 2001
        AND i.i_brand = 'Brand#12'
        AND p.p_discount_active = 'Y'
        AND s.s_floor_space > 8000000
        AND r_cr.r_reason_desc LIKE '%Not the product%'
        AND wp.wp_type = 'C'
        AND t_cs.t_hour BETWEEN 8 AND 18
        AND d_page_start.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        d_cs.d_year
)
SELECT
    item_id,
    product_name,
    brand,
    year,
    total_catalog_profit,
    total_web_profit,
    (total_catalog_profit + total_web_profit) AS total_profit,
    total_catalog_return_amount,
    total_store_return_amount,
    total_web_return_amount,
    RANK() OVER (PARTITION BY brand ORDER BY (total_catalog_profit + total_web_profit) DESC) AS brand_item_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 100
