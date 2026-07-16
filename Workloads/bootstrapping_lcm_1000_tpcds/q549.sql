WITH joined AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_day_name,
        i.i_item_sk,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_current_price,
        cr.cr_order_number,
        cr.cr_return_amount,
        cr.cr_net_loss,
        wr.wr_order_number,
        wr.wr_return_amt,
        wr.wr_net_loss,
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d.d_date_sk
),
agg AS (
    SELECT
        d_year,
        d_month_seq,
        i_category,
        i_class,
        i_brand,
        s_store_sk,
        s_store_name,
        s_city,
        s_state,
        SUM(cr_return_amount) AS catalog_return_amount,
        SUM(wr_return_amt) AS web_return_amount,
        SUM(cr_net_loss) AS catalog_net_loss,
        SUM(wr_net_loss) AS web_net_loss,
        COUNT(DISTINCT cr_order_number) AS catalog_order_cnt,
        COUNT(DISTINCT wr_order_number) AS web_order_cnt
    FROM joined
    WHERE d_year >= 2020
    GROUP BY
        d_year,
        d_month_seq,
        i_category,
        i_class,
        i_brand,
        s_store_sk,
        s_store_name,
        s_city,
        s_state
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    i_class,
    i_brand,
    catalog_return_amount,
    web_return_amount,
    catalog_net_loss,
    web_net_loss,
    catalog_order_cnt,
    web_order_cnt,
    (catalog_return_amount - web_return_amount) AS return_amount_diff,
    (catalog_net_loss - web_net_loss) AS net_loss_diff,
    s_store_name,
    s_city,
    s_state,
    ROW_NUMBER() OVER (
        PARTITION BY s_store_sk
        ORDER BY (catalog_return_amount + web_return_amount) DESC
    ) AS store_return_rank
FROM agg
ORDER BY return_amount_diff DESC
LIMIT 100
