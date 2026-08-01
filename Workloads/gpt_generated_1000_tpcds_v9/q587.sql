WITH base AS (
    SELECT
        d_cs_sold.d_year AS year,
        i.i_brand,
        i.i_category,
        p.p_discount_active,
        cs.cs_ext_sales_price AS catalog_sales_price,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_ext_sales_price AS store_sales_price,
        ss.ss_net_profit AS store_net_profit,
        cr.cr_return_amount AS catalog_return_amount,
        sr.sr_return_amt AS store_return_amount,
        cs.cs_order_number,
        ss.ss_ticket_number,
        p.p_cost,
        r_cr.r_reason_desc AS catalog_return_reason
    FROM catalog_sales cs
    JOIN date_dim d_cs_sold
        ON cs.cs_sold_date_sk = d_cs_sold.d_date_sk
    JOIN time_dim t_cs_sold
        ON cs.cs_sold_time_sk = t_cs_sold.t_time_sk
    JOIN date_dim d_cs_ship
        ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
    JOIN customer_demographics cd_cs_bill
        ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
    JOIN customer_demographics cd_cs_ship
        ON cs.cs_ship_cdemo_sk = cd_cs_ship.cd_demo_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN date_dim d_cr_return
        ON cr.cr_returned_date_sk = d_cr_return.d_date_sk
    JOIN time_dim t_cr_return
        ON cr.cr_returned_time_sk = t_cr_return.t_time_sk
    JOIN customer_demographics cd_cr_refunded
        ON cr.cr_refunded_cdemo_sk = cd_cr_refunded.cd_demo_sk
    JOIN customer_demographics cd_cr_returning
        ON cr.cr_returning_cdemo_sk = cd_cr_returning.cd_demo_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN catalog_page cp_cr
        ON cr.cr_catalog_page_sk = cp_cr.cp_catalog_page_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    JOIN date_dim d_ss_sold
        ON ss.ss_sold_date_sk = d_ss_sold.d_date_sk
    JOIN time_dim t_ss_sold
        ON ss.ss_sold_time_sk = t_ss_sold.t_time_sk
    JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d_sr_return
        ON sr.sr_returned_date_sk = d_sr_return.d_date_sk
    JOIN time_dim t_sr_return
        ON sr.sr_return_time_sk = t_sr_return.t_time_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN customer_demographics cd_sr
        ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
    JOIN date_dim d_p_start
        ON p.p_start_date_sk = d_p_start.d_date_sk
    JOIN date_dim d_p_end
        ON p.p_end_date_sk = d_p_end.d_date_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    WHERE
        d_cs_sold.d_year = 2001
        AND i.i_class = 'sports-apparel'
        AND p.p_discount_active = 'Y'
        AND r_cr.r_reason_desc = 'Damaged'
        AND p.p_cost > 5000
),
agg AS (
    SELECT
        year,
        i_brand,
        i_category,
        CASE WHEN p_discount_active = 'Y' THEN 'Discounted' ELSE 'FullPrice' END AS promo_type,
        SUM(catalog_sales_price) AS total_catalog_sales,
        SUM(store_sales_price) AS total_store_sales,
        SUM(catalog_return_amount) AS total_catalog_returns,
        SUM(store_return_amount) AS total_store_returns,
        COUNT(DISTINCT cs_order_number) AS distinct_catalog_orders,
        COUNT(DISTINCT ss_ticket_number) AS distinct_store_tickets,
        AVG(catalog_sales_price) AS avg_catalog_sales_price,
        MAX(p_cost) AS max_promo_cost,
        SUM(catalog_net_profit + store_net_profit) AS total_net_profit,
        SUM(catalog_sales_price + store_sales_price) AS total_sales
    FROM base
    GROUP BY
        year,
        i_brand,
        i_category,
        CASE WHEN p_discount_active = 'Y' THEN 'Discounted' ELSE 'FullPrice' END
)
SELECT
    year,
    i_brand,
    i_category,
    promo_type,
    total_catalog_sales,
    total_store_sales,
    total_catalog_returns,
    total_store_returns,
    distinct_catalog_orders,
    distinct_store_tickets,
    avg_catalog_sales_price,
    max_promo_cost,
    total_net_profit,
    total_sales,
    SUM(total_sales) OVER (PARTITION BY i_brand ORDER BY year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_sales_by_brand_year,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY total_sales DESC
LIMIT 100
