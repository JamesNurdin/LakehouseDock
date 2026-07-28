WITH item_returns AS (
    SELECT
        i.i_item_sk,
        i.i_brand,
        i.i_category,
        SUM(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS web_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
        AVG(i.i_current_price) AS avg_price
    FROM tpcds.item i
    LEFT JOIN tpcds.store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    WHERE i.i_manager_id IN (98, 40, 19)
      AND i.i_current_price BETWEEN 0.5 AND 9.0
      AND i.i_rec_start_date >= DATE '1999-01-01'
    GROUP BY i.i_item_sk, i.i_brand, i.i_category
)
SELECT
    brand,
    SUM(total_net_loss) AS brand_total_net_loss,
    AVG(avg_item_net_loss) AS brand_avg_item_net_loss
FROM (
    SELECT
        i_brand AS brand,
        (store_net_loss + web_net_loss) AS total_net_loss,
        (store_net_loss + web_net_loss) / NULLIF((store_return_cnt + web_return_cnt), 0) AS avg_item_net_loss
    FROM item_returns
) b
GROUP BY brand
HAVING SUM(total_net_loss) > 1000
ORDER BY brand_total_net_loss DESC
LIMIT 10
