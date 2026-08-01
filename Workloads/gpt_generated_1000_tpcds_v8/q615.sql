WITH
    order_union AS (
        SELECT cs_order_number FROM catalog_sales
        UNION
        SELECT cr_order_number FROM catalog_returns
    ),
    order_excl AS (
        SELECT cs_order_number FROM catalog_sales
        EXCEPT
        SELECT cr_order_number FROM catalog_returns
    ),
    promo_channels AS (
        SELECT p.p_promo_sk,
               p.p_promo_id,
               channel
        FROM promotion p
        CROSS JOIN UNNEST(ARRAY[p.p_channel_email, p.p_channel_tv, p.p_channel_radio]) AS t(channel)
    ),
    joined AS (
        SELECT
            d.d_year,
            d.d_month_seq,
            cp.cp_department,
            p.p_promo_id,
            cd.cd_gender,
            ss.ss_net_paid_inc_tax,
            cs.cs_quantity * cs.cs_sales_price AS line_total,
            CASE WHEN ss.ss_net_paid_inc_tax > 5000 THEN 'High' ELSE 'Low' END AS sales_category,
            s.s_store_name,
            r.r_reason_desc
        FROM date_dim d
        JOIN catalog_sales cs
            ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN store_sales ss
            ON ss.ss_sold_date_sk = d.d_date_sk
        FULL OUTER JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
        JOIN catalog_returns cr
            ON cr.cr_returned_date_sk = d.d_date_sk
        JOIN web_returns wr
            ON wr.wr_returned_date_sk = d.d_date_sk
        JOIN time_dim t
            ON cs.cs_sold_time_sk = t.t_time_sk
        JOIN promotion p
            ON cs.cs_promo_sk = p.p_promo_sk
        JOIN catalog_page cp
            ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_demographics cd
            ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN reason r
            ON cr.cr_reason_sk = r.r_reason_sk
        WHERE d.d_year = 2001
          AND p.p_discount_active = 'Y'
          AND cp.cp_department = 'DEPARTMENT'
          AND ss.ss_net_paid_inc_tax > 1000
          AND cd.cd_gender = 'M'
          AND cs.cs_item_sk IN (SELECT cr2.cr_item_sk FROM catalog_returns cr2)
    ),
    agg AS (
        SELECT
            d_year,
            d_month_seq,
            cp_department,
            p_promo_id,
            cd_gender,
            s_store_name,
            r_reason_desc,
            sales_category,
            SUM(line_total) AS total_sales,
            SUM(ss_net_paid_inc_tax) AS total_net_paid,
            COUNT(*) AS txn_count
        FROM joined
        GROUP BY
            d_year,
            d_month_seq,
            cp_department,
            p_promo_id,
            cd_gender,
            s_store_name,
            r_reason_desc,
            sales_category
    )
SELECT
    d_year,
    d_month_seq,
    cp_department,
    p_promo_id,
    cd_gender,
    s_store_name,
    r_reason_desc,
    sales_category,
    total_sales,
    total_net_paid,
    txn_count,
    SUM(total_sales) OVER (PARTITION BY d_year ORDER BY d_month_seq ROWS UNBOUNDED PRECEDING) AS cumulative_sales_year
FROM agg
ORDER BY total_sales DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
