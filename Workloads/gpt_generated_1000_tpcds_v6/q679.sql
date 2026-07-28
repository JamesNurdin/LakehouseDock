WITH distinct_pages AS (
    SELECT DISTINCT wp_web_page_sk, wp_url
    FROM web_page
    WHERE wp_link_count > 5
),
sales_data AS (
    SELECT
        i.i_category,
        td.t_hour,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_txn_cnt,
        'catalog' AS sales_source
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_list_price > 100
      AND cs.cs_quantity >= 2
      AND c.c_birth_year >= 1960
      AND cd.cd_gender = 'M'
    GROUP BY i.i_category, td.t_hour

    UNION ALL

    SELECT
        i.i_category,
        td.t_hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_txn_cnt,
        'store' AS sales_source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE ss.ss_sales_price > 150
      AND ss.ss_quantity >= 1
      AND c.c_birth_year >= 1960
      AND cd.cd_marital_status = 'M'
    GROUP BY i.i_category, td.t_hour

    UNION ALL

    SELECT
        i.i_category,
        td.t_hour,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_txn_cnt,
        'web' AS sales_source
    FROM web_sales ws
    LEFT JOIN distinct_pages dp ON ws.ws_web_page_sk = dp.wp_web_page_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sales_price > 120
      AND ws.ws_quantity >= 1
      AND c.c_birth_year >= 1960
      AND cd.cd_education_status = 'College'
    GROUP BY i.i_category, td.t_hour
),
returns_agg AS (
    SELECT
        i.i_category,
        td.t_hour,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_txn_cnt,
        r.r_reason_desc
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c_refund ON wr.wr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN customer_demographics cd_refund ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
    WHERE wr.wr_return_quantity > 0
      AND r.r_reason_id = 'AAAAAAAADAAAAAAA'
      AND c_refund.c_birth_year >= 1960
      AND cd_refund.cd_credit_rating = 'Excellent'
    GROUP BY i.i_category, td.t_hour, r.r_reason_desc
)
SELECT
    sd.i_category,
    sd.t_hour,
    sd.sales_source,
    SUM(sd.total_net_paid) AS sum_net_paid,
    SUM(sd.total_discount) AS sum_discount,
    SUM(sd.sales_txn_cnt) AS total_sales_txns
FROM sales_data sd
GROUP BY sd.i_category, sd.t_hour, sd.sales_source

UNION ALL

SELECT
    ra.i_category,
    ra.t_hour,
    ra.r_reason_desc AS sales_source,
    SUM(ra.total_return_amt) AS sum_net_paid,
    SUM(ra.total_net_loss) AS sum_discount,
    SUM(ra.return_txn_cnt) AS total_sales_txns
FROM returns_agg ra
GROUP BY ra.i_category, ra.t_hour, ra.r_reason_desc

ORDER BY i_category, t_hour, sales_source
LIMIT 100
