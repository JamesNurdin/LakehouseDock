WITH item_sales AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_category_id,
        i.i_brand,
        i.i_manufact,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_ext_wholesale_cost,
        ss.ss_promo_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_return_tax,
        sr.sr_return_ship_cost
    FROM
        item i
        JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
        JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    WHERE
        i.i_category_id = 6
        AND inv.inv_quantity_on_hand > 0
        AND ss.ss_promo_sk IN (172, 754, 1061)
        AND sr.sr_return_tax > (SELECT AVG(sr2.sr_return_tax) FROM store_returns sr2)
)
SELECT
    i_category,
    i_brand,
    i_manufact,
    SUM(ss_quantity) AS total_quantity_sold,
    SUM(sr_return_quantity) AS total_quantity_returned,
    SUM(ss_ext_sales_price) AS total_sales_amount,
    SUM(sr_return_amt) AS total_return_amount,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(sr_net_loss) AS total_net_loss,
    AVG(ss_ext_wholesale_cost) AS avg_wholesale_cost,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
FROM
    item_sales
GROUP BY
    i_category,
    i_brand,
    i_manufact
ORDER BY
    total_net_profit DESC
LIMIT 100
