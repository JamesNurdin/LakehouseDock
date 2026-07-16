WITH base_agg AS (
    SELECT
        cp.cp_department,
        cp.cp_type,
        d.d_year,
        d.d_month_seq,
        s.s_state,
        s.s_city,
        COUNT(DISTINCT cr.cr_order_number) AS catalog_order_cnt,
        SUM(cr.cr_return_amount) AS total_catalog_return_amt,
        AVG(cr.cr_return_quantity) AS avg_catalog_return_qty,
        SUM(cr.cr_fee) AS total_catalog_fee,
        SUM(cr.cr_net_loss) AS total_catalog_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS web_order_cnt,
        SUM(wr.wr_return_amt) AS total_web_return_amt,
        AVG(wr.wr_return_quantity) AS avg_web_return_qty,
        SUM(wr.wr_fee) AS total_web_fee,
        SUM(wr.wr_net_loss) AS total_web_net_loss,
        (SUM(cr.cr_fee) + SUM(wr.wr_fee)) AS total_fees,
        (SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_cp_end ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN date_dim d_cp_start ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2022
      AND cp.cp_type = 'Promo'
      AND s.s_state = 'CA'
      AND d_cp_end.d_year = 2022
      AND d_cp_start.d_year = 2022
    GROUP BY
        cp.cp_department,
        cp.cp_type,
        d.d_year,
        d.d_month_seq,
        s.s_state,
        s.s_city
    HAVING SUM(cr.cr_return_amount) > 10000
)
SELECT
    cp_department,
    cp_type,
    d_year,
    d_month_seq,
    s_state,
    s_city,
    catalog_order_cnt,
    total_catalog_return_amt,
    avg_catalog_return_qty,
    total_catalog_fee,
    total_catalog_net_loss,
    web_order_cnt,
    total_web_return_amt,
    avg_web_return_qty,
    total_web_fee,
    total_web_net_loss,
    total_fees,
    total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_loss DESC) AS state_return_rank
FROM base_agg
ORDER BY total_net_loss DESC
LIMIT 100
