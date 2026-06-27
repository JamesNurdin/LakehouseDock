WITH brand_reason_agg AS (
    SELECT
        i.i_brand,
        i.i_category,
        r.r_reason_desc,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss,
        AVG(wr.wr_return_amt) AS avg_return_amount
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    GROUP BY i.i_brand, i.i_category, r.r_reason_desc
)
SELECT
    brand_reason_agg.i_brand,
    brand_reason_agg.i_category,
    brand_reason_agg.r_reason_desc,
    brand_reason_agg.total_return_quantity,
    brand_reason_agg.total_return_amount,
    brand_reason_agg.total_net_loss,
    brand_reason_agg.avg_return_amount,
    ROW_NUMBER() OVER (
        PARTITION BY brand_reason_agg.i_brand
        ORDER BY brand_reason_agg.total_net_loss DESC
    ) AS loss_rank_within_brand
FROM brand_reason_agg
ORDER BY brand_reason_agg.i_brand, loss_rank_within_brand
