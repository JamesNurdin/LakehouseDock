WITH sales_agg AS (
    SELECT
        d_sold.d_year AS sales_year,
        cc.cc_state AS call_center_state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN date_dim d_sold
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d_open
        ON cc.cc_open_date_sk = d_open.d_date_sk
    JOIN date_dim d_close
        ON cc.cc_closed_date_sk = d_close.d_date_sk
    JOIN date_dim d_cp_start
        ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_promo_start
        ON p.p_start_date_sk = d_promo_start.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_open.d_date_sk
    WHERE cs.cs_net_paid > 500
      AND cs.cs_quantity BETWEEN 1 AND 10
      AND p.p_channel_dmail = 'Y'
      AND cp.cp_type = 'monthly'
      AND d_sold.d_year = 2002
      AND ws.web_country = 'United States'
    GROUP BY GROUPING SETS (
        (d_sold.d_year, cc.cc_state),
        (d_sold.d_year),
        (cc.cc_state),
        ()
    )
)
SELECT
    sales_year,
    call_center_state,
    total_net_paid,
    total_ext_sales,
    order_cnt,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank,
    AVG(total_net_paid) OVER () AS avg_total_net_paid
FROM sales_agg
WHERE total_net_paid > 10000
ORDER BY total_net_paid DESC
LIMIT 100
