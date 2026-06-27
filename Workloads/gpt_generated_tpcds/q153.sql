WITH returns_by_gender AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd_ret.cd_gender AS returning_gender,
        cd_ref.cd_gender AS refunded_gender,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd_ret ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    LEFT JOIN customer_demographics cd_ref ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY d.d_year, d.d_month_seq, i.i_category, cd_ret.cd_gender, cd_ref.cd_gender
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    returning_gender,
    refunded_gender,
    total_return_quantity,
    total_return_amount,
    total_net_loss,
    ROUND(total_net_loss / NULLIF(total_return_amount, 0), 2) AS net_loss_per_return_amount,
    RANK() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_net_loss DESC) AS net_loss_category_rank
FROM returns_by_gender
ORDER BY d_year, d_month_seq, net_loss_category_rank
