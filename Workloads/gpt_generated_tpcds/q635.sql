/*
   Return analysis by item brand and web page type.
   For each brand‑page combination we compute the number of returns,
   total quantity returned, total return amount and total net loss.
   Then we rank the page types within each brand by net loss and
   keep the top 3 page types per brand.
*/
WITH returns_detail AS (
    SELECT
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_net_loss,
        i.i_brand,
        i.i_category,
        i.i_product_name,
        wp.wp_type,
        cust.c_customer_id,
        cust.c_first_name,
        cust.c_last_name
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer cust
        ON wr.wr_refunded_customer_sk = cust.c_customer_sk
),
brand_page_agg AS (
    SELECT
        i_brand,
        wp_type,
        COUNT(*) AS return_count,
        SUM(wr_return_quantity) AS total_quantity,
        SUM(wr_return_amt) AS total_return_amount,
        SUM(wr_net_loss) AS total_net_loss
    FROM returns_detail
    GROUP BY i_brand, wp_type
),
ranked AS (
    SELECT
        i_brand,
        wp_type,
        return_count,
        total_quantity,
        total_return_amount,
        total_net_loss,
        ROW_NUMBER() OVER (PARTITION BY i_brand ORDER BY total_net_loss DESC) AS rank_within_brand
    FROM brand_page_agg
)
SELECT
    i_brand,
    wp_type,
    return_count,
    total_quantity,
    total_return_amount,
    total_net_loss,
    rank_within_brand
FROM ranked
WHERE rank_within_brand <= 3
ORDER BY i_brand, rank_within_brand
