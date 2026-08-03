/* goal: Compare sales performance and return losses per item, highlighting items with high sales or high return loss, using a full outer join between sales and returns, distinct aggregates, a table sample, a scalar sub‑query for average price, and a UNION ALL of two filtered sets. */
WITH sales_item AS (
    SELECT
        i.i_item_id,
        i.i_brand,
        COUNT(DISTINCT ss.ss_customer_sk) AS distinct_customers,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(DISTINCT ss.ss_sales_price) AS distinct_sales_price_sum
    FROM (
        SELECT * FROM store_sales TABLESAMPLE BERNOULLI (10)
    ) ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    WHERE td.t_shift = 'first'
    GROUP BY i.i_item_id, i.i_brand
),
returns_item AS (
    SELECT
        i.i_item_id,
        i.i_category,
        COUNT(DISTINCT cr.cr_refunded_customer_sk) AS distinct_refunded_customers,
        SUM(cr.cr_net_loss) AS total_loss,
        SUM(DISTINCT cr.cr_return_amount) AS distinct_return_amount_sum
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_id, i.i_category
),
full_item AS (
    SELECT
        COALESCE(s.i_item_id, r.i_item_id) AS item_id,
        s.i_brand,
        r.i_category,
        s.distinct_customers,
        r.distinct_refunded_customers,
        s.total_sales,
        r.total_loss,
        s.distinct_sales_price_sum,
        r.distinct_return_amount_sum
    FROM sales_item s
    FULL OUTER JOIN returns_item r
        ON s.i_item_id = r.i_item_id
)
SELECT
    fi.item_id,
    fi.i_brand,
    fi.i_category,
    fi.distinct_customers,
    fi.distinct_refunded_customers,
    fi.total_sales,
    fi.total_loss,
    fi.distinct_sales_price_sum,
    fi.distinct_return_amount_sum,
    (SELECT AVG(i_current_price) FROM item) AS avg_price
FROM (
    SELECT * FROM full_item
    WHERE total_sales > (SELECT AVG(i_current_price) FROM item) * 10
    UNION ALL
    SELECT * FROM full_item
    WHERE total_loss > (SELECT AVG(i_current_price) FROM item) * 5
) fi
ORDER BY fi.total_sales DESC NULLS LAST
LIMIT 100
