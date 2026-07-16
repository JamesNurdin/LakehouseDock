WITH aggregated AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        s.s_state,
        w.web_city,
        COUNT(DISTINCT cr.cr_order_number) AS orders_returned,
        SUM(cr.cr_return_quantity) AS total_qty_returned,
        SUM(cr.cr_return_amount) AS total_amount_returned,
        SUM(cr.cr_net_loss) AS total_net_loss,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
    JOIN web_site w
        ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND i.i_category = 'Electronics'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        i.i_brand,
        s.s_state,
        w.web_city
)
SELECT
    a.*,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_loss DESC) AS yearly_loss_rank,
    ROW_NUMBER() OVER (PARTITION BY a.d_year, a.i_category ORDER BY a.total_amount_returned DESC) AS category_return_rank
FROM aggregated a
ORDER BY a.total_net_loss DESC, a.d_year, a.d_month_seq
LIMIT 200
