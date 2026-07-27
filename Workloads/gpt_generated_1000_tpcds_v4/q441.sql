WITH filtered AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_reason_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_account_credit,
        i.i_brand,
        i.i_item_id,
        i.i_product_name,
        i.i_container,
        i.i_manufact,
        i.i_rec_end_date,
        r.r_reason_desc,
        r.r_reason_id
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE i.i_rec_end_date = DATE '2000-10-26'
      AND i.i_container = 'Unknown'
      AND i.i_manufact = 'callyeingeing'
      AND wr.wr_return_quantity > 1
      AND wr.wr_return_amt > 20.00
      AND r.r_reason_desc LIKE '%did not%'
)
SELECT
    f.i_brand,
    f.i_item_id,
    f.i_product_name,
    f.r_reason_desc,
    COUNT(*) AS return_cnt,
    SUM(f.wr_return_quantity) AS total_qty,
    SUM(f.wr_return_amt) AS total_return_amt,
    AVG(f.wr_return_amt) AS avg_return_amt,
    SUM(f.wr_net_loss) AS total_loss,
    CASE WHEN SUM(f.wr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category,
    (SELECT MAX(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_item_sk = f.wr_item_sk) AS max_return_amt_for_item,
    RANK() OVER (PARTITION BY f.i_brand ORDER BY SUM(f.wr_net_loss) DESC) AS brand_loss_rank
FROM filtered f
GROUP BY
    f.i_brand,
    f.i_item_id,
    f.i_product_name,
    f.r_reason_desc,
    f.wr_item_sk
ORDER BY total_loss DESC
LIMIT 100
