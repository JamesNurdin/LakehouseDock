/*
   Analytical query: total return activity by item category together with the gender of the
   refunded and returning customers. The result is ranked per refunded‑gender by net loss.
*/
WITH agg AS (
    SELECT
        i.i_category,
        cd_ref.cd_gender AS refunded_gender,
        cd_ret.cd_gender AS returning_gender,
        COUNT(*) AS return_count,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(DISTINCT wr.wr_order_number) AS distinct_orders
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd_ref
        ON wr.wr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN customer_demographics cd_ret
        ON wr.wr_returning_cdemo_sk = cd_ret.cd_demo_sk
    GROUP BY i.i_category, cd_ref.cd_gender, cd_ret.cd_gender
)
SELECT
    i_category,
    refunded_gender,
    returning_gender,
    return_count,
    total_quantity,
    total_return_amount,
    total_net_loss,
    distinct_orders,
    RANK() OVER (PARTITION BY refunded_gender ORDER BY total_net_loss DESC) AS net_loss_rank_by_refunded_gender
FROM agg
ORDER BY total_net_loss DESC
LIMIT 200
