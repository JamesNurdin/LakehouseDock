WITH base AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_returning_customer_sk,
        cr.cr_returning_addr_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_returning_hdemo_sk,
        cr.cr_reason_sk,
        cr.cr_order_number,
        d_ret.d_year AS ret_year,
        d_ret.d_month_seq AS ret_month_seq,
        cp.cp_department,
        cp.cp_catalog_page_number,
        r.r_reason_desc,
        cust.c_customer_id,
        cust_addr.ca_state,
        cd.cd_gender,
        ws.web_name,
        ARRAY[cr.cr_return_quantity, cr.cr_return_amount] AS metrics_arr
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN customer cust ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN customer_address cust_addr ON cr.cr_refunded_addr_sk = cust_addr.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_site ws ON ws.web_open_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
      AND cr.cr_return_quantity >= 1
      AND cr.cr_return_amount > 20
)
SELECT
    base.cp_department,
    base.cp_catalog_page_number,
    base.r_reason_desc,
    base.c_customer_id,
    base.ca_state,
    base.cd_gender,
    base.web_name,
    base.cr_return_amount,
    CASE WHEN base.cr_return_amount > 100 THEN 'HIGH' ELSE 'LOW' END AS amount_category,
    RANK() OVER (PARTITION BY base.cp_department ORDER BY base.cr_return_amount DESC) AS dept_rank,
    ROW_NUMBER() OVER (ORDER BY base.cr_return_amount DESC) AS global_row_num,
    CASE WHEN metric_idx = 1 THEN 'RETURN_QUANTITY' ELSE 'RETURN_AMOUNT' END AS metric_name,
    metric_val
FROM base
CROSS JOIN UNNEST(base.metrics_arr) WITH ORDINALITY AS t(metric_val, metric_idx)
ORDER BY base.cr_return_amount DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
