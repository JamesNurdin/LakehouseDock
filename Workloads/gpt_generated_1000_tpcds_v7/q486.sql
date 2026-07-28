WITH sr AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_return_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_return_tax,
        sr.sr_net_loss,
        sr.sr_return_quantity,
        sr.sr_ticket_number,
        sr.sr_cdemo_sk,
        sr.sr_hdemo_sk,
        sr.sr_addr_sk
    FROM store_returns sr
    WHERE sr.sr_return_ship_cost > 50
        AND sr.sr_refunded_cash BETWEEN 100 AND 5000
        AND sr.sr_return_tax > 5
),
wr AS (
    SELECT
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        wr.wr_order_number,
        wr.wr_refunded_cdemo_sk,
        wr.wr_refunded_hdemo_sk,
        wr.wr_refunded_addr_sk,
        wr.wr_returning_cdemo_sk,
        wr.wr_returning_hdemo_sk,
        wr.wr_returning_addr_sk,
        wr.wr_web_page_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 1
        AND wr.wr_return_amt > 20
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_class,
    cd.cd_credit_rating,
    SUM(sr.sr_net_loss) AS store_net_loss,
    SUM(wr.wr_net_loss) AS web_net_loss,
    (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_cnt,
    RANK() OVER (PARTITION BY i.i_brand ORDER BY (SUM(sr.sr_net_loss) + SUM(wr.wr_net_loss)) DESC) AS brand_rank
FROM item i
LEFT JOIN sr ON sr.sr_item_sk = i.i_item_sk
LEFT JOIN wr ON wr.wr_item_sk = i.i_item_sk
LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = sr.sr_cdemo_sk
LEFT JOIN household_demographics hd ON hd.hd_demo_sk = sr.sr_hdemo_sk
LEFT JOIN customer_address ca ON ca.ca_address_sk = sr.sr_addr_sk
LEFT JOIN web_page wp ON wp.wp_web_page_sk = wr.wr_web_page_sk
WHERE i.i_brand_id IN (1003001, 2004001)
    AND i.i_current_price > 20
    AND cd.cd_dep_count <= 3
    AND wp.wp_type = 'product'
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    i.i_class,
    cd.cd_credit_rating,
    i.i_brand
ORDER BY total_net_loss DESC
LIMIT 100
