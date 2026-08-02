WITH combined_facts AS (
    SELECT
        d_cs.d_year,
        i.i_category,
        i.i_brand,
        p.p_promo_id,
        cs.cs_net_paid AS catalog_net_paid,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        cr.cr_net_loss AS catalog_return_loss,
        wr.wr_net_loss AS web_return_loss,
        cs.cs_order_number
    FROM catalog_sales cs
    JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    LEFT JOIN catalog_returns cr 
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    LEFT JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN time_dim t_ss ON ss.ss_sold_time_sk = t_ss.t_time_sk
    LEFT JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    LEFT JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d_cs.d_year BETWEEN 2001 AND 2002
      AND i.i_brand = 'Brand#12'
      AND ca_bill.ca_state = 'CA'
      AND cc.cc_market_manager IS NOT NULL
      AND p.p_discount_active = 'Y'
      AND t_cs.t_hour BETWEEN 8 AND 20
      AND (r_cr.r_reason_desc LIKE '%damaged%' OR r_cr.r_reason_desc IS NULL)
),
aggregated AS (
    SELECT
        d_year,
        i_category,
        SUM(catalog_net_paid) AS total_catalog_sales,
        SUM(store_net_paid) AS total_store_sales,
        SUM(web_net_paid) AS total_web_sales,
        SUM(catalog_return_loss) AS total_catalog_return_loss,
        SUM(web_return_loss) AS total_web_return_loss,
        COUNT(DISTINCT cs_order_number) AS total_orders
    FROM combined_facts
    GROUP BY ROLLUP (d_year, i_category)
)
SELECT
    agg.d_year,
    agg.i_category,
    agg.total_catalog_sales,
    agg.total_store_sales,
    agg.total_web_sales,
    agg.total_catalog_return_loss,
    agg.total_web_return_loss,
    agg.total_orders,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year ORDER BY (agg.total_catalog_sales + agg.total_store_sales + agg.total_web_sales) DESC) AS rank_within_year,
    (SELECT SUM(total_catalog_sales + total_store_sales + total_web_sales) FROM aggregated) AS overall_total_sales
FROM aggregated agg
WHERE agg.i_category IS NOT NULL
  AND agg.d_year IN (
        SELECT d_year
        FROM date_dim
        WHERE d_year >= 2001
          AND d_year <= 2002
        INTERSECT
        SELECT d_year
        FROM date_dim
        WHERE d_year = 2001
        EXCEPT
        SELECT d_year
        FROM date_dim
        WHERE d_year = 2000
    )
ORDER BY agg.d_year DESC, rank_within_year
LIMIT 100
