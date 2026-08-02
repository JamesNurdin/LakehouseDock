/*
Goal: Identify the top items (by combined net loss from catalog and web returns) that have significant return activity in both channels, rank them within their categories, and compare each item's loss to the overall average loss.
*/
WITH
catalog_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(cr.cr_net_loss) AS catalog_net_loss,
        COUNT(*) AS catalog_return_cnt
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE cr.cr_return_quantity > 0
      AND cc.cc_tax_percentage > 0.05
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category
),
web_agg AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_category,
        SUM(wr.wr_net_loss) AS web_net_loss,
        COUNT(*) AS web_return_cnt
    FROM web_returns wr
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    WHERE wr.wr_return_quantity > 0
    GROUP BY i.i_item_sk, i.i_item_id, i.i_category
),
filtered_items AS (
    SELECT
        ca.i_item_sk,
        ca.i_item_id,
        ca.i_category,
        ca.catalog_net_loss,
        wa.web_net_loss,
        ca.catalog_return_cnt,
        wa.web_return_cnt,
        (ca.catalog_net_loss + wa.web_net_loss) AS total_net_loss
    FROM catalog_agg ca
    JOIN web_agg wa
        ON ca.i_item_sk = wa.i_item_sk
    WHERE (ca.catalog_net_loss > 1000 OR wa.web_net_loss > 1000)
),
intersected_items AS (
    SELECT i_item_sk FROM filtered_items WHERE catalog_return_cnt > 5
    INTERSECT
    SELECT i_item_sk FROM filtered_items WHERE web_return_cnt > 5
)
SELECT
    fi.i_item_sk,
    fi.i_item_id,
    fi.i_category,
    fi.catalog_net_loss,
    fi.web_net_loss,
    fi.total_net_loss,
    ROW_NUMBER() OVER (PARTITION BY fi.i_category ORDER BY fi.total_net_loss DESC) AS category_rank,
    (SELECT AVG(total_net_loss) FROM filtered_items) AS avg_total_net_loss_all_items
FROM filtered_items fi
JOIN intersected_items ii
    ON fi.i_item_sk = ii.i_item_sk
WHERE fi.total_net_loss > (SELECT AVG(total_net_loss) FROM filtered_items)
ORDER BY fi.total_net_loss DESC
LIMIT 100
