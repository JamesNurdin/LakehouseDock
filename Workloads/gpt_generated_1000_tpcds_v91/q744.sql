WITH base_data AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_promo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ticket_number,
        ss.ss_addr_sk,
        s.s_store_id            AS store_id,
        s.s_state               AS store_state,
        s.s_gmt_offset,
        s.s_tax_percentage,
        i.i_category            AS category,
        i.i_brand               AS brand,
        i.i_product_name,
        i.i_current_price,
        p_ss.p_promo_name       AS promo_name,
        p_ss.p_discount_active  AS discount_active,
        t_ss.t_hour             AS sale_hour,
        t_ss.t_am_pm,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cc.cc_company,
        cc.cc_mkt_id,
        cp.cp_department,
        w.w_city                AS warehouse_city,
        w.w_state,
        ca_bill.ca_city         AS bill_city,
        ca_ship.ca_city         AS ship_city,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        r.r_reason_desc,
        sr.sr_return_time_sk,
        ca_sr.ca_city           AS return_city,
        ca_sr.ca_state          AS return_state
    FROM store_sales ss
    INNER JOIN time_dim t_ss
        ON ss.ss_sold_time_sk = t_ss.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p_ss
        ON ss.ss_promo_sk = p_ss.p_promo_sk
        AND p_ss.p_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_store_sk = s.s_store_sk
        AND sr.sr_item_sk = i.i_item_sk
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN time_dim t_sr
        ON sr.sr_return_time_sk = t_sr.t_time_sk
    LEFT JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    INNER JOIN catalog_sales cs
        ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_sold_time_sk = t_ss.t_time_sk
    INNER JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    INNER JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    INNER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN promotion p_cs
        ON cs.cs_promo_sk = p_cs.p_promo_sk
        AND p_cs.p_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
),
agg_data AS (
    SELECT
        store_id,
        store_state,
        ss_store_sk                AS store_sk,
        category,
        brand,
        ss_item_sk                 AS item_sk,
        promo_name,
        sale_hour,
        SUM(ss_ext_sales_price)   AS total_store_sales,
        SUM(cs_ext_sales_price)   AS total_catalog_sales,
        SUM(COALESCE(sr_return_amt, 0)) AS total_return_amount,
        COUNT(DISTINCT ss_ticket_number) AS sales_txn_cnt,
        COUNT(sr_return_amt)      AS return_txn_cnt
    FROM base_data
    WHERE cc_company = 5
      AND store_state = 'CA'
      AND brand = 'BrandX'
      AND discount_active = 'Y'
      AND sale_hour BETWEEN 9 AND 17
      AND warehouse_city = 'MILLER'
    GROUP BY
        store_id,
        store_state,
        ss_store_sk,
        category,
        brand,
        ss_item_sk,
        promo_name,
        sale_hour
)
SELECT
    a.store_id,
    a.store_state,
    a.category,
    a.brand,
    a.promo_name,
    a.sale_hour,
    a.total_store_sales,
    a.total_catalog_sales,
    a.total_return_amount,
    a.sales_txn_cnt,
    a.return_txn_cnt,
    ROW_NUMBER() OVER (PARTITION BY a.store_id ORDER BY a.total_store_sales DESC) AS sales_rank,
    SUM(a.total_store_sales) OVER (PARTITION BY a.store_state ORDER BY a.sale_hour
                                   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_store_sales_by_state,
    top_r.r_reason_desc AS top_return_reason
FROM agg_data a
LEFT JOIN LATERAL (
    SELECT r.r_reason_desc
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_store_sk = a.store_sk
      AND sr.sr_item_sk = a.item_sk
    ORDER BY sr.sr_return_amt DESC
    LIMIT 1
) AS top_r ON TRUE
LIMIT 100
