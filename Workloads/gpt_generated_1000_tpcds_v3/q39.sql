SELECT
    i_brand_id,
    i_brand,
    i_size,
    total_quantity,
    total_return_amt,
    total_net_loss,
    value_category
FROM (
    SELECT
        i.i_brand_id,
        i.i_brand,
        i.i_size,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High Value' ELSE 'Low Value' END AS value_category
    FROM
        web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE
        i.i_brand_id IN (6008007, 2004002)
        AND i.i_size IN ('small', 'large')
        AND wr.wr_return_quantity > 20
    GROUP BY
        i.i_brand_id,
        i.i_brand,
        i.i_size

    UNION ALL

    SELECT
        i.i_brand_id,
        i.i_brand,
        i.i_size,
        SUM(wr.wr_return_quantity) AS total_quantity,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        CASE WHEN SUM(wr.wr_return_amt) > 1000 THEN 'High Value' ELSE 'Low Value' END AS value_category
    FROM
        web_returns wr
        JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE
        i.i_brand_id IN (1003001, 1001001)
        AND i.i_size = 'extra large'
        AND wr.wr_return_quantity <= 20
    GROUP BY
        i.i_brand_id,
        i.i_brand,
        i.i_size
) AS combined
ORDER BY total_net_loss DESC
LIMIT 100
